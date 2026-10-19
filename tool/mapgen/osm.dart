import 'package:fogcatcher/models/geo_point.dart';

/// One OSM way or multipolygon, reduced to what the rasterizer needs.
class OsmFeature {
  OsmFeature({
    required this.id,
    required this.tags,
    this.outers = const [],
    this.inners = const [],
    this.line = const [],
  });
  final String id; // e.g. "way/123", "relation/456"
  final Map<String, String> tags;
  final List<List<GeoPoint>> outers, inners;
  final List<GeoPoint> line; // set when the way is not an area

  bool get isArea => outers.isNotEmpty;
}

List<GeoPoint> _geometry(Object? g) => [
  for (final p in (g as List<dynamic>? ?? const []))
    GeoPoint(
      ((p as Map<String, dynamic>)['lat'] as num).toDouble(),
      (p['lon'] as num).toDouble(),
    ),
];

Map<String, String> _tags(Map<String, dynamic> e) =>
    (e['tags'] as Map<String, dynamic>? ?? const {}).map(
      (k, v) => MapEntry(k, '$v'),
    );

bool _closed(List<GeoPoint> g) => g.length >= 4 && g.first == g.last;

/// Closed highways (roundabouts) and barriers are lines unless tagged area=yes.
bool _wayIsArea(Map<String, String> tags, List<GeoPoint> g) {
  if (!_closed(g)) return false;
  if (tags['area'] == 'yes') return true;
  if (tags['area'] == 'no') return false;
  return !tags.containsKey('highway') && !tags.containsKey('barrier');
}

List<OsmFeature> parseFeatures(Map<String, dynamic> osm) {
  final out = <OsmFeature>[];
  for (final e in (osm['elements'] as List<dynamic>)) {
    final el = e as Map<String, dynamic>;
    final tags = _tags(el);
    final id = '${el['type']}/${el['id']}';
    if (el['type'] == 'way') {
      final g = _geometry(el['geometry']);
      if (g.length < 2) continue;
      out.add(
        _wayIsArea(tags, g)
            ? OsmFeature(id: id, tags: tags, outers: [g])
            : OsmFeature(id: id, tags: tags, line: g),
      );
    } else if (el['type'] == 'relation' && tags['type'] == 'multipolygon') {
      final members = (el['members'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .where((m) => m['type'] == 'way');
      List<List<GeoPoint>> role(String r) => stitchRings([
        for (final m in members)
          if ((m['role'] ?? 'outer') == r || (r == 'outer' && m['role'] == ''))
            _geometry(m['geometry']),
      ]);
      final outers = role('outer');
      if (outers.isEmpty) continue;
      out.add(
        OsmFeature(id: id, tags: tags, outers: outers, inners: role('inner')),
      );
    }
  }
  return out;
}

/// Joins way pieces sharing end nodes into closed rings; open leftovers are dropped.
List<List<GeoPoint>> stitchRings(List<List<GeoPoint>> pieces) {
  final pool = [
    for (final p in pieces)
      if (p.length >= 2) [...p],
  ];
  final rings = <List<GeoPoint>>[];
  while (pool.isNotEmpty) {
    final ring = pool.removeLast();
    var grew = true;
    while (!_closed(ring) && grew) {
      grew = false;
      for (var i = 0; i < pool.length; i++) {
        final p = pool[i];
        if (p.first == ring.last) {
          ring.addAll(p.skip(1));
        } else if (p.last == ring.last) {
          ring.addAll(p.reversed.skip(1));
        } else {
          continue;
        }
        pool.removeAt(i);
        grew = true;
        break;
      }
    }
    if (_closed(ring)) rings.add(ring);
  }
  return rings;
}

/// Keeps only fields the generator reads so the committed cache stays small.
Map<String, dynamic> trimOsm(Map<String, dynamic> osm) => {
  'note': 'Overpass extract, (c) OpenStreetMap contributors, ODbL.',
  'timestamp': (osm['osm3s'] as Map<String, dynamic>?)?['timestamp_osm_base'],
  'elements': [
    for (final e in (osm['elements'] as List<dynamic>))
      {
        'type': (e as Map<String, dynamic>)['type'],
        'id': e['id'],
        if (e['tags'] != null) 'tags': e['tags'],
        if (e['geometry'] != null) 'geometry': _trimGeom(e['geometry']),
        if (e['members'] != null)
          'members': [
            for (final m in (e['members'] as List<dynamic>))
              if ((m as Map<String, dynamic>)['type'] == 'way')
                {
                  'type': 'way',
                  'ref': m['ref'],
                  'role': m['role'],
                  'geometry': _trimGeom(m['geometry']),
                },
          ],
      },
  ],
};

List<Map<String, double>> _trimGeom(Object? g) => [
  for (final p in (g as List<dynamic>? ?? const []))
    if (p != null)
      {
        'lat': ((p as Map<String, dynamic>)['lat'] as num).toDouble(),
        'lon': (p['lon'] as num).toDouble(),
      },
];
