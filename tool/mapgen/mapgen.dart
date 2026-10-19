// Builds assets/sites/<id>/tilemap.json from OpenStreetMap; CLI in main.dart, also used by new_site.dart.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/site.dart';
import 'package:fogcatcher/models/terrain.dart';
import 'package:fogcatcher/models/tile_map.dart';

import 'classify.dart';
import 'osm.dart';
import 'overpass.dart';
import 'png.dart';
import 'rasterizer.dart';

// Same as lib tileCellMeters (test/tool/mapgen_test.dart checks); lib/config pulls in dart:ui, which dart run lacks.
const tileCellMeters = 4.0;

final _boundaryRef = RegExp(r'^(way|relation)/[1-9][0-9]*$');

/// Optional site.json `boundary` (`way/<id>` or `relation/<id>`): playable area instead of the circle.
String? boundaryOf(Map<String, dynamic> siteJson) {
  final v = siteJson['boundary'];
  if (v == null) return null;
  if (v is String && _boundaryRef.hasMatch(v)) return v;
  throw FormatException(
    'boundary must be "way/<id>" or "relation/<id>", got $v',
  );
}

/// Reads site.json, fetches or reuses OSM data, writes tilemap.json and returns it.
Future<TileMap> buildTilemap(String id, {bool refresh = false}) async {
  final json = readJson('assets/sites/$id/site.json');
  final site = Site.fromJson(json);
  final osm = await loadOsm(site, refresh: refresh);
  final map = generate(
    site,
    parseFeatures(osm),
    readOverrides(id),
    boundary: boundaryOf(json),
  );
  File(
    'assets/sites/$id/tilemap.json',
  ).writeAsStringSync('${jsonEncode(map.toJson())}\n');
  return map;
}

const _paintOrder = [
  Terrain.wood,
  Terrain.sand,
  Terrain.court,
  Terrain.parking,
  Terrain.road,
  Terrain.path,
  Terrain.water,
  Terrain.building,
];

Map<String, dynamic> readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Future<Map<String, dynamic>> loadOsm(Site site, {bool refresh = false}) async {
  final cache = File('tool/mapgen/cache/${site.id}.osm.json');
  if (!refresh && cache.existsSync()) {
    return jsonDecode(cache.readAsStringSync()) as Map<String, dynamic>;
  }
  stdout.writeln('fetching Overpass for ${site.id}…');
  final osm = trimOsm(await fetchOsm(site.bounds));
  cache
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('${jsonEncode(osm)}\n');
  return osm;
}

List<List<GeoPoint>> readOverrides(String id) {
  final f = File('tool/mapgen/overrides/$id.json');
  if (!f.existsSync()) return const [];
  final polys = (readJson(f.path)['void'] as List<dynamic>? ?? const []);
  return [
    for (final p in polys)
      [
        for (final pt in (p as List<dynamic>))
          GeoPoint.fromJson(pt as Map<String, dynamic>),
      ],
  ];
}

TileMap generate(
  Site site,
  List<OsmFeature> features,
  List<List<GeoPoint>> overrides, {
  String? boundary,
}) {
  final r = Rasterizer(
    bounds: site.bounds,
    refLat: site.center.lat,
    cellMeters: tileCellMeters,
  );
  final usable = features.where((f) => !isVoid(f.tags)).toList();
  for (final t in _paintOrder) {
    for (final f in usable.where((f) => classify(f.tags) == t)) {
      _paint(r, f, t);
    }
  }
  for (final f in features.where((f) => f.isArea && isVoid(f.tags))) {
    for (final o in f.outers) {
      r.fillPolygon(o, f.inners, Terrain.voidZone);
    }
  }
  for (final f in features) {
    final w = golfVoidStroke(f.tags);
    if (w == null) continue;
    for (final line in f.isArea ? f.outers : [f.line]) {
      r.strokeLine(line, w, Terrain.voidZone);
    }
  }
  if (boundary != null) {
    final rel = features.firstWhere(
      (f) => f.id == boundary && f.isArea,
      orElse: () => throw StateError(
        'boundary $boundary is not a closed area in the OSM data',
      ),
    );
    final outer = rel.outers.reduce((a, b) => a.length >= b.length ? a : b);
    r.voidOutsidePolygon(outer);
  } else {
    r.voidOutsideCircle(site.center, site.radiusMeters);
  }
  for (final poly in overrides) {
    r.fillPolygon(poly, const [], Terrain.voidZone);
  }
  return r.build(site.id, _labels(r, usable));
}

void _paint(Rasterizer r, OsmFeature f, Terrain t) {
  if (f.isArea) {
    for (final o in f.outers) {
      r.fillPolygon(o, f.inners, t);
    }
  } else {
    r.strokeLine(f.line, strokeWidth(t) ?? 4, t);
  }
}

bool _labelled(Map<String, String> tags) =>
    tags['name'] != null &&
    (tags.containsKey('building') ||
        tags['leisure'] == 'swimming_pool' ||
        tags['amenity'] == 'restaurant' ||
        tags['amenity'] == 'bar');

List<TileLabel> _labels(Rasterizer r, List<OsmFeature> features) {
  final seen = <String>{};
  final out = <TileLabel>[];
  for (final f in features.where((f) => f.isArea && _labelled(f.tags))) {
    final ring = f.outers.first;
    var lat = 0.0, lng = 0.0;
    for (final p in ring.skip(1)) {
      lat += p.lat;
      lng += p.lng;
    }
    final n = ring.length - 1;
    final m = r.projection.toMeters(GeoPoint(lat / n, lng / n));
    final x = m.x ~/ r.cellMeters, y = m.y ~/ r.cellMeters;
    if (x < 0 || y < 0 || x >= r.width || y >= r.height) continue;
    if (r.cells[y * r.width + x] == Terrain.voidZone.index) continue;
    if (seen.add(f.tags['name']!)) out.add(TileLabel(f.tags['name']!, x, y));
  }
  return out;
}

void printStats(TileMap map) {
  final counts = List.filled(Terrain.values.length, 0);
  for (final c in map.cells) {
    counts[c]++;
  }
  stdout.writeln(
    '${map.siteId}: ${map.width}×${map.height} cells, ${map.labels.length} labels',
  );
  for (final t in Terrain.values) {
    final pct = 100 * counts[t.index] / map.cells.length;
    stdout.writeln('  ${t.name.padRight(9)} ${pct.toStringAsFixed(1)}%');
  }
}

List<GeoPoint> itemPoints(String id) {
  final f = File('assets/sites/$id/items.json');
  if (!f.existsSync()) return const [];
  return [
    for (final i in (readJson(f.path)['items'] as List<dynamic>))
      GeoPoint(
        ((i as Map<String, dynamic>)['lat'] as num).toDouble(),
        (i['lng'] as num).toDouble(),
      ),
  ];
}

const previewColors = <Terrain, int>{
  Terrain.grass: 0x7CB342,
  Terrain.wood: 0x2E7D32,
  Terrain.sand: 0xE6D49A,
  Terrain.court: 0xD7CCC8,
  Terrain.parking: 0x9E9E9E,
  Terrain.road: 0x505050,
  Terrain.path: 0xB08850,
  Terrain.water: 0x3F8FD8,
  Terrain.building: 0xB5503C,
  Terrain.voidZone: 0x000000,
};

/// One pixel per cell, items as orange 3×3 squares.
Uint8List renderPreview(TileMap map, List<GeoPoint> items, Site site) {
  final rgb = Uint8List(map.width * map.height * 3);
  void put(int x, int y, int c) {
    if (x < 0 || y < 0 || x >= map.width || y >= map.height) return;
    final o = (y * map.width + x) * 3;
    rgb
      ..[o] = c >> 16
      ..[o + 1] = (c >> 8) & 0xFF
      ..[o + 2] = c & 0xFF;
  }

  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      put(x, y, previewColors[map.at(x, y)]!);
    }
  }
  final r = Rasterizer(
    bounds: site.bounds,
    refLat: site.center.lat,
    cellMeters: map.cellMeters,
  );
  for (final p in items) {
    final m = r.projection.toMeters(p);
    final cx = m.x ~/ map.cellMeters, cy = m.y ~/ map.cellMeters;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        put(cx + dx, cy + dy, 0xF26530);
      }
    }
  }
  return encodeRgbPng(map.width, map.height, rgb);
}
