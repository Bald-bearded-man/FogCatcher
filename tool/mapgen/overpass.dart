import 'dart:convert';
import 'dart:io';

import 'package:fogcatcher/models/site.dart';
import 'package:http/http.dart' as http;

const _endpoints = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
];
const _osmApi = 'https://api.openstreetmap.org/api/0.6/map.json';
const userAgent = 'fogcatcher-mapgen/0.1';

const _wayKeys =
    'building|highway|leisure|landuse|natural|amenity|golf|sport|access|water|surface';
const _relationKeys =
    'building|leisure|landuse|natural|golf|sport|type|tourism';
const _poiKeys = 'amenity|leisure|tourism|shop|historic|sport|office|craft';

String overpassQuery(GeoBounds b) {
  final bbox = '${b.south},${b.west},${b.north},${b.east}';
  return '''
[out:json][timeout:90];
(
  way($bbox)[~"^($_wayKeys)\$"~"."];
  relation($bbox)[~"^($_relationKeys)\$"~"."];
);
out geom;
''';
}

/// Point POIs used only by the item spot picker.
String poiQuery(GeoBounds b) {
  final bbox = '${b.south},${b.west},${b.north},${b.east}';
  return '''
[out:json][timeout:60];
node($bbox)[~"^($_poiKeys)\$"~"."];
out;
''';
}

/// Ways and multipolygons in [b] with geometry, Overpass `out geom` shape.
Future<Map<String, dynamic>> fetchOsm(GeoBounds b) async {
  try {
    return await runOverpass(overpassQuery(b));
  } on StateError catch (e) {
    return fromOsmApi(await _osmApiMap(b, e));
  }
}

/// Tagged nodes in [b], Overpass `out` shape.
Future<Map<String, dynamic>> fetchPois(GeoBounds b) async {
  try {
    return await runOverpass(poiQuery(b));
  } on StateError catch (e) {
    return poisFromOsmApi(await _osmApiMap(b, e));
  }
}

/// Tries each mirror in turn for a few rounds, pausing to respect the 1 req/s etiquette.
Future<Map<String, dynamic>> runOverpass(String query, {int rounds = 2}) async {
  final errors = <String>[];
  for (final url in [for (var r = 0; r < rounds; r++) ..._endpoints]) {
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'User-Agent': userAgent},
        body: {'data': query},
      );
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      errors.add('$url: HTTP ${res.statusCode}');
    } on Exception catch (e) {
      errors.add('$url: $e');
    }
    await Future<void>.delayed(const Duration(seconds: 5));
  }
  throw StateError('Overpass failed: ${errors.join('; ')}');
}

final _mapCache = <String, Map<String, dynamic>>{};

/// Fallback when every Overpass mirror is down: one OSM API map call (small sites only).
Future<Map<String, dynamic>> _osmApiMap(GeoBounds b, StateError cause) async {
  checkOsmApiArea(b, cause);
  final bbox = '${b.west},${b.south},${b.east},${b.north}';
  final cached = _mapCache[bbox];
  if (cached != null) return cached;
  stdout.writeln('$cause\nfalling back to the OSM API map call…');
  final res = await http.get(
    Uri.parse('$_osmApi?bbox=$bbox'),
    headers: {'User-Agent': userAgent},
  );
  if (res.statusCode != 200) {
    throw StateError('OSM API: HTTP ${res.statusCode} ${res.body}');
  }
  return _mapCache[bbox] =
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
}

/// The OSM API map call refuses boxes over 0.25 square degrees.
const osmApiMaxArea = 0.25;

void checkOsmApiArea(GeoBounds b, [Object? cause]) {
  final area = (b.north - b.south) * (b.east - b.west);
  if (area > osmApiMaxArea) {
    throw StateError(
      '${cause ?? 'Overpass unavailable'}\nOSM API fallback refused: bbox is '
      '${area.toStringAsFixed(3)} deg², over the API limit of $osmApiMaxArea; '
      'retry when Overpass is back',
    );
  }
}

bool _hasKey(Object? tags, String keys) {
  final set = keys.split('|').toSet();
  return (tags as Map<String, dynamic>? ?? const {}).keys.any(set.contains);
}

List<Map<String, dynamic>> _elements(Map<String, dynamic> map, String type) => [
  for (final e in (map['elements'] as List<dynamic>))
    if ((e as Map<String, dynamic>)['type'] == type) e,
];

/// Converts an OSM API map response to the Overpass `out geom` shape the generator reads.
/// Relation members outside the bbox have no geometry, so their rings may stay open.
Map<String, dynamic> fromOsmApi(Map<String, dynamic> map) {
  final nodes = {
    for (final n in _elements(map, 'node'))
      n['id']: {'lat': n['lat'], 'lon': n['lon']},
  };
  List<Map<String, dynamic>> geometry(Map<String, dynamic> way) => [
    for (final ref in (way['nodes'] as List<dynamic>)) ?nodes[ref],
  ];
  final ways = {for (final w in _elements(map, 'way')) w['id']: w};
  return {
    'elements': [
      for (final w in ways.values)
        if (_hasKey(w['tags'], _wayKeys))
          {
            'type': 'way',
            'id': w['id'],
            'tags': w['tags'],
            'geometry': geometry(w),
          },
      for (final r in _elements(map, 'relation'))
        if (_hasKey(r['tags'], _relationKeys))
          {
            'type': 'relation',
            'id': r['id'],
            'tags': r['tags'],
            'members': [
              for (final m in (r['members'] as List<dynamic>))
                if ((m as Map<String, dynamic>)['type'] == 'way' &&
                    ways.containsKey(m['ref']))
                  {
                    'type': 'way',
                    'ref': m['ref'],
                    'role': m['role'],
                    'geometry': geometry(ways[m['ref']]!),
                  },
            ],
          },
    ],
  };
}

Map<String, dynamic> poisFromOsmApi(Map<String, dynamic> map) => {
  'elements': [
    for (final n in _elements(map, 'node'))
      if (_hasKey(n['tags'], _poiKeys)) n,
  ],
};
