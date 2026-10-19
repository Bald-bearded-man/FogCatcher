// Picks item spots from OSM landmarks and the site tilemap; used by new_site.dart and pick.dart.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:fogcatcher/game/geo.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/site.dart';
import 'package:fogcatcher/models/terrain.dart';
import 'package:fogcatcher/models/tile_map.dart';

import '../classify.dart';
import '../osm.dart';
import '../overpass.dart';

const itemRadius = 20.0;
// Find disc (20 m) plus margin stays clear of golf, archery and the boundary.
const voidClearance = 28.0;
const accessReach = 8.0; // spot must be this close to a path or road
const _walkable = {
  Terrain.grass,
  Terrain.path,
  Terrain.court,
  Terrain.parking,
  Terrain.sand,
};
const _privateBuildings = {
  'house',
  'detached',
  'semidetached_house',
  'residential',
  'apartments',
  'garage',
  'garages',
  'shed',
  'greenhouse',
  'roof',
  'terrace',
  'bungalow',
  'farm_auxiliary',
};

class Candidate {
  Candidate(this.landmark, this.point, this.score, {this.exact = false});
  final String landmark;
  final GeoPoint point;
  final int score;
  final bool exact; // already a validated cell centre: no snapping
}

const zoneScore = 2; // after landmarks, before path fillers
const roadClearance = 30.0; // zone spots stay this far from roads

int _score(Map<String, String> t) {
  if (t['leisure'] == 'swimming_pool') return 10;
  if (const {
    'restaurant',
    'bar',
    'cafe',
    'pub',
    'theatre',
    'arts_centre',
    'cinema',
  }.contains(t['amenity'])) {
    return 9;
  }
  if (t['amenity'] == 'place_of_worship' || t.containsKey('historic')) return 8;
  if (const {
    'pitch',
    'sports_centre',
    'park',
    'garden',
    'playground',
    'fitness_station',
  }.contains(t['leisure'])) {
    return 7;
  }
  if (t['tourism'] != null || t['amenity'] != null || t['shop'] != null) {
    return 6;
  }
  final name = t['name'] ?? '';
  if (RegExp(
    r'bar|restaurant|th[ée][aâ]tre',
    caseSensitive: false,
  ).hasMatch(name)) {
    return 9;
  }
  if (t['building'] != null && t['name'] != null) return 6;
  return 0;
}

/// Off-path cells (e.g. an open forest) inside `S,W,N,E:max`, clear of void and roads.
List<Candidate> zoneCandidates(
  TileMap map,
  Site site,
  List<OsmFeature> features,
  String zone,
) {
  final box = zone.split(':').first.split(',').map(double.parse).toList();
  final proj = LocalProjection(origin: map.origin, refLat: site.center.lat);
  final roads = [
    for (final f in features)
      if (!f.isArea && classify(f.tags) == Terrain.road)
        [for (final p in f.line) proj.toMeters(p)],
  ];
  bool nearRoad(double x, double y) =>
      roads.any((line) => _segmentNear(line, x, y, roadClearance));
  final out = <Candidate>[];
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      final cx = (x + 0.5) * map.cellMeters, cy = (y + 0.5) * map.cellMeters;
      final g = proj.fromMeters(cx, cy);
      if (g.lat < box[0] ||
          g.lng < box[1] ||
          g.lat > box[2] ||
          g.lng > box[3]) {
        continue;
      }
      if (map.at(x, y) == Terrain.voidZone || !_clearOfVoid(map, x, y)) {
        continue;
      }
      if (haversineMeters(site.center, g) + itemRadius >
          site.radiusMeters - 2) {
        continue;
      }
      if (nearRoad(cx, cy)) continue;
      out.add(Candidate('zone cell $x,$y', g, zoneScore, exact: true));
    }
  }
  return out;
}

bool _segmentNear(
  List<({double x, double y})> line,
  double x,
  double y,
  double d,
) {
  for (var i = 0; i + 1 < line.length; i++) {
    final a = line[i], b = line[i + 1];
    final dx = b.x - a.x, dy = b.y - a.y;
    final len2 = dx * dx + dy * dy;
    final t = len2 == 0
        ? 0.0
        : (((x - a.x) * dx + (y - a.y) * dy) / len2).clamp(0.0, 1.0);
    final px = a.x + t * dx - x, py = a.y + t * dy - y;
    if (px * px + py * py < d * d) return true;
  }
  return false;
}

bool _clearOfVoid(TileMap map, int x, int y) {
  final clear = (voidClearance / map.cellMeters).ceil();
  for (var dy = -clear; dy <= clear; dy++) {
    for (var dx = -clear; dx <= clear; dx++) {
      if (map.at(x + dx, y + dy) == Terrain.voidZone) return false;
    }
  }
  return true;
}

/// Path cells fill the remaining slots, nearest to the centre first.
List<Candidate> pathCandidates(TileMap map, Site site) {
  final proj = LocalProjection(origin: map.origin, refLat: site.center.lat);
  return [
    for (var y = 0; y < map.height; y += 2)
      for (var x = 0; x < map.width; x += 2)
        if (map.at(x, y) == Terrain.path)
          Candidate(
            'path cell $x,$y',
            proj.fromMeters(
              (x + 0.5) * map.cellMeters,
              (y + 0.5) * map.cellMeters,
            ),
            1,
          ),
  ];
}

String _describe(Map<String, String> t) {
  final kind = [
    for (final k in [
      'leisure',
      'amenity',
      'sport',
      'shop',
      'tourism',
      'historic',
    ])
      if (t[k] != null) '$k=${t[k]}',
  ];
  if (kind.isEmpty && t['building'] != null) kind.add('building');
  return [if (t['name'] != null) t['name'], kind.join(' ')].join(' · ');
}

// Named pools are resort pools (guests only, often tagged private); unnamed ones
// without a public access tag are usually in private gardens.
bool _publicSpot(Map<String, String> t) {
  if (t['leisure'] == 'swimming_pool') {
    return t['name'] != null ||
        const {'yes', 'public', 'customers'}.contains(t['access']);
  }
  return t['access'] != 'private';
}

bool _eligible(Map<String, String> t) =>
    !isVoid(t) &&
    !_privateBuildings.contains(t['building']) &&
    _publicSpot(t) &&
    t['amenity'] != 'fuel' &&
    _score(t) > 0;

List<Candidate> areaCandidates(List<OsmFeature> features) => [
  for (final f in features.where((f) => f.isArea && _eligible(f.tags)))
    Candidate(_describe(f.tags), _centroid(f.outers.first), _score(f.tags)),
];

List<Candidate> nodeCandidates(Map<String, dynamic> pois) => [
  for (final e in (pois['elements'] as List<dynamic>))
    if (_eligible(_tagsOf(e)))
      Candidate(
        _describe(_tagsOf(e)),
        GeoPoint(
          ((e as Map<String, dynamic>)['lat'] as num).toDouble(),
          (e['lon'] as num).toDouble(),
        ),
        _score(_tagsOf(e)) + 1, // named POI nodes are the most specific
      ),
];

Map<String, String> _tagsOf(Object? e) =>
    ((e as Map<String, dynamic>)['tags'] as Map<String, dynamic>? ?? const {})
        .map((k, v) => MapEntry(k, '$v'));

GeoPoint _centroid(List<GeoPoint> ring) {
  final pts = ring.length > 1 && ring.first == ring.last
      ? ring.sublist(1)
      : ring;
  var lat = 0.0, lng = 0.0;
  for (final p in pts) {
    lat += p.lat;
    lng += p.lng;
  }
  return GeoPoint(lat / pts.length, lng / pts.length);
}

/// Greedy: best score first, then closest to the centre; one spot per landmark name.
List<Candidate> pick(
  Site site,
  TileMap map,
  List<Candidate> all,
  int count,
  double minSpacing, {
  int zoneMax = 0,
  bool verbose = false,
}) {
  var zoneTaken = 0;
  final proj = LocalProjection(origin: map.origin, refLat: site.center.lat);
  all.sort((a, b) {
    final s = b.score.compareTo(a.score);
    if (s != 0) return s;
    return haversineMeters(
      site.center,
      a.point,
    ).compareTo(haversineMeters(site.center, b.point));
  });
  final out = <Candidate>[];
  final names = <String>{};
  for (final c in all) {
    if (out.length == count) break;
    if (c.score == zoneScore && zoneTaken >= zoneMax) continue;
    final spot = c.exact ? c.point : _spot(map, proj, site, c.point);
    if (spot == null) {
      if (verbose) stdout.writeln('  no valid spot: ${c.landmark}');
      continue;
    }
    if (!names.add(c.landmark)) continue;
    if (out.any((o) => haversineMeters(o.point, spot) < minSpacing)) {
      if (verbose) stdout.writeln('  too close: ${c.landmark}');
      names.remove(c.landmark);
      continue;
    }
    out.add(Candidate(c.landmark, spot, c.score));
    if (c.score == zoneScore) zoneTaken++;
  }
  return out;
}

/// Nearest valid cell centre within 30 m of [p], or null.
GeoPoint? _spot(TileMap map, LocalProjection proj, Site site, GeoPoint p) {
  final m = proj.toMeters(p);
  final cx = m.x ~/ map.cellMeters, cy = m.y ~/ map.cellMeters;
  final reach = (30 / map.cellMeters).ceil();
  GeoPoint? best;
  var bestD = double.infinity;
  for (var y = cy - reach; y <= cy + reach; y++) {
    for (var x = cx - reach; x <= cx + reach; x++) {
      final d = math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2));
      if (d >= bestD || !_valid(map, x, y)) continue;
      final g = proj.fromMeters(
        (x + 0.5) * map.cellMeters,
        (y + 0.5) * map.cellMeters,
      );
      if (haversineMeters(site.center, g) + itemRadius >
          site.radiusMeters - 2) {
        continue;
      }
      best = g;
      bestD = d;
    }
  }
  return best;
}

bool _valid(TileMap map, int x, int y) {
  if (!_walkable.contains(map.at(x, y))) return false;
  final clear = (voidClearance / map.cellMeters).ceil();
  final near = (accessReach / map.cellMeters).ceil();
  var reachable = false;
  for (var dy = -clear; dy <= clear; dy++) {
    for (var dx = -clear; dx <= clear; dx++) {
      final t = map.at(x + dx, y + dy);
      if (t == Terrain.voidZone) return false;
      if (dx.abs() <= near &&
          dy.abs() <= near &&
          (t == Terrain.path || t == Terrain.road)) {
        reachable = true;
      }
    }
  }
  return reachable;
}

/// Up to [count] spots, at least [spacing] m apart: landmarks first, then zone cells, then path cells.
/// [zone] is `S,W,N,E:K`: up to K off-path spots in that box, clear of void and roads.
List<Candidate> pickSpots(
  Site site,
  TileMap map,
  List<OsmFeature> features,
  Map<String, dynamic> pois, {
  required int count,
  required double spacing,
  String? zone,
  bool verbose = false,
}) => pick(
  site,
  map,
  [
    ...areaCandidates(features),
    ...nodeCandidates(pois),
    ...pathCandidates(map, site),
    if (zone != null) ...zoneCandidates(map, site, features, zone),
  ],
  count,
  spacing,
  zoneMax: zone == null ? 0 : int.parse(zone.split(':').last),
  verbose: verbose,
);

/// Item ids: first letter of the site id plus a two-digit number (`d01`).
String spotId(String siteId, int index) =>
    '${siteId[0]}${(index + 1).toString().padLeft(2, '0')}';

double roundCoord(double v) => (v * 1e7).round() / 1e7;

/// POI nodes for [site], cached next to the OSM extract.
Future<Map<String, dynamic>> loadPois(Site site, {bool refresh = false}) async {
  final f = File('tool/mapgen/cache/${site.id}.pois.osm.json');
  if (!refresh && f.existsSync()) {
    return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  }
  final pois = await fetchPois(site.bounds);
  final slim = {
    'note': 'Overpass extract, (c) OpenStreetMap contributors, ODbL.',
    'elements': [
      for (final e in (pois['elements'] as List<dynamic>))
        {
          'id': (e as Map<String, dynamic>)['id'],
          'lat': e['lat'],
          'lon': e['lon'],
          'tags': e['tags'],
        },
    ],
  };
  f
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('${jsonEncode(slim)}\n');
  return slim;
}

/// `tool/mapgen/seed/<id>.json`: spot ids, landmarks and positions (read by the solution maps).
String seedJson(String siteId, List<Candidate> spots) =>
    '${const JsonEncoder.withIndent('  ').convert({
      'id': siteId,
      'items': [
        for (var i = 0; i < spots.length; i++) {'id': spotId(siteId, i), 'landmark': spots[i].landmark, 'lat': roundCoord(spots[i].point.lat), 'lng': roundCoord(spots[i].point.lng), 'radiusMeters': itemRadius},
      ],
    })}\n';
