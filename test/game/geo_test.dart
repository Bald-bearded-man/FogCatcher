import 'dart:math' as math;
import 'package:fogcatcher/game/geo.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('haversine: 1 degree of latitude is ~111.2 km', () {
    expect(
      haversineMeters(const GeoPoint(0, 0), const GeoPoint(1, 0)),
      closeTo(111195, 5),
    );
  });
  test('haversine: zero for identical points', () {
    expect(
      haversineMeters(const GeoPoint(43.65, 6.99), const GeoPoint(43.65, 6.99)),
      0,
    );
  });
  test('projection round-trips within 1 cm at the test site', () {
    final proj = LocalProjection(
      origin: const GeoPoint(43.6560059, 6.9889561),
      refLat: 43.6524704,
    );
    const p = GeoPoint(43.650875, 6.99746);
    final m = proj.toMeters(p);
    final back = proj.fromMeters(m.x, m.y);
    expect(haversineMeters(p, back), lessThan(0.01));
  });
  test('projection: east and south are positive', () {
    final proj = LocalProjection(
      origin: const GeoPoint(43.656, 6.988),
      refLat: 43.652,
    );
    final m = proj.toMeters(const GeoPoint(43.655, 6.989));
    expect(m.x, greaterThan(0));
    expect(m.y, greaterThan(0));
  });
  test('projection distance agrees with haversine over 500 m', () {
    final proj = LocalProjection(
      origin: const GeoPoint(43.656, 6.988),
      refLat: 43.652,
    );
    const a = GeoPoint(43.652, 6.990), b = GeoPoint(43.6545, 6.9945);
    final ma = proj.toMeters(a), mb = proj.toMeters(b);
    final d = math.sqrt(
      (ma.x - mb.x) * (ma.x - mb.x) + (ma.y - mb.y) * (ma.y - mb.y),
    );
    final h = haversineMeters(a, b);
    expect(d, closeTo(h, h * 0.005)); // within 0.5 %
  });
}
