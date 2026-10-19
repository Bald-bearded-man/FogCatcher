import 'geo_point.dart';

class GeoBounds {
  const GeoBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });
  final double south, west, north, east;
  factory GeoBounds.fromJson(Map<String, dynamic> j) => GeoBounds(
    south: (j['south'] as num).toDouble(),
    west: (j['west'] as num).toDouble(),
    north: (j['north'] as num).toDouble(),
    east: (j['east'] as num).toDouble(),
  );
}

class Site {
  const Site({
    required this.id,
    required this.name,
    required this.center,
    required this.radiusMeters,
    required this.bounds,
  });
  final String id;
  final String name;
  final GeoPoint center;
  final double radiusMeters;
  final GeoBounds bounds;
  factory Site.fromJson(Map<String, dynamic> j) => Site(
    id: j['id'] as String,
    name: j['name'] as String,
    center: GeoPoint.fromJson(j['center'] as Map<String, dynamic>),
    radiusMeters: (j['radiusMeters'] as num).toDouble(),
    bounds: GeoBounds.fromJson(j['bounds'] as Map<String, dynamic>),
  );
}
