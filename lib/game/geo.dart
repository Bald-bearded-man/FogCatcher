import 'dart:math' as math;
import '../models/geo_point.dart';

const double earthRadiusMeters = 6371000;
double _rad(double d) => d * math.pi / 180;

double haversineMeters(GeoPoint a, GeoPoint b) {
  final dLat = _rad(b.lat - a.lat), dLng = _rad(b.lng - a.lng);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.lat)) *
          math.cos(_rad(b.lat)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * earthRadiusMeters * math.asin(math.min(1, math.sqrt(h)));
}

/// Equirectangular projection around [origin] (north-west corner), scaled at [refLat].
class LocalProjection {
  LocalProjection({required this.origin, required double refLat})
    : _mPerDegLat = earthRadiusMeters * math.pi / 180,
      _mPerDegLng = earthRadiusMeters * math.pi / 180 * math.cos(_rad(refLat));
  final GeoPoint origin;
  final double _mPerDegLat, _mPerDegLng;

  /// Metres east and south of origin.
  ({double x, double y}) toMeters(GeoPoint p) => (
    x: (p.lng - origin.lng) * _mPerDegLng,
    y: (origin.lat - p.lat) * _mPerDegLat,
  );

  GeoPoint fromMeters(double x, double y) =>
      GeoPoint(origin.lat - y / _mPerDegLat, origin.lng + x / _mPerDegLng);
}

/// "350 m" below 1 km, otherwise "1.2 km".
String formatDistance(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(1)} km';
