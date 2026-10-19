import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/site.dart';
import 'package:fogcatcher/models/terrain.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/mapgen/rasterizer.dart';

void main() {
  const bounds = GeoBounds(
    south: 43.650,
    west: 6.990,
    north: 43.651,
    east: 6.9914,
  ); // ~111 m × ~113 m
  Rasterizer r() => Rasterizer(bounds: bounds, refLat: 43.6505, cellMeters: 4);

  test('grid size follows bounds / cell size', () {
    final x = r();
    expect(x.width, inInclusiveRange(27, 30));
    expect(x.height, inInclusiveRange(27, 29));
  });
  test('fillPolygon paints inside, not outside', () {
    final x = r()
      ..fillPolygon(
        const [
          GeoPoint(43.6508, 6.9902),
          GeoPoint(43.6508, 6.9906),
          GeoPoint(43.6504, 6.9906),
          GeoPoint(43.6504, 6.9902),
        ],
        const [],
        Terrain.water,
      );
    final m = x.build('t', const []);
    expect(m.at(5, 9), Terrain.water); // inside the square
    expect(m.at(25, 25), Terrain.grass); // far corner
  });
  test('holes stay unpainted', () {
    final x = r()
      ..fillPolygon(
        const [
          GeoPoint(43.6509, 6.9901),
          GeoPoint(43.6509, 6.9912),
          GeoPoint(43.6501, 6.9912),
          GeoPoint(43.6501, 6.9901),
        ],
        const [
          [
            GeoPoint(43.6506, 6.9905),
            GeoPoint(43.6506, 6.9908),
            GeoPoint(43.6504, 6.9908),
            GeoPoint(43.6504, 6.9905),
          ],
        ],
        Terrain.building,
      );
    final m = x.build('t', const []);
    expect(m.at(14, 14), Terrain.grass);
    expect(m.at(4, 4), Terrain.building);
  });
  test('strokeLine paints a continuous path', () {
    final x = r()
      ..strokeLine(
        const [GeoPoint(43.6505, 6.9900), GeoPoint(43.6505, 6.9914)],
        3,
        Terrain.path,
      );
    final m = x.build('t', const []);
    final row = m.height ~/ 2;
    for (var cx = 0; cx < m.width; cx++) {
      expect([
        m.at(cx, row - 1),
        m.at(cx, row),
        m.at(cx, row + 1),
      ], contains(Terrain.path));
    }
  });
  test('voidOutsideCircle blackens corners only', () {
    final x = r()..voidOutsideCircle(const GeoPoint(43.6505, 6.9907), 50);
    final m = x.build('t', const []);
    expect(m.at(0, 0), Terrain.voidZone);
    expect(m.at(m.width ~/ 2, m.height ~/ 2), Terrain.grass);
  });
  test('voidOutsidePolygon keeps only the inside', () {
    final x = r()
      ..voidOutsidePolygon(const [
        GeoPoint(43.6508, 6.9902),
        GeoPoint(43.6508, 6.9906),
        GeoPoint(43.6504, 6.9906),
        GeoPoint(43.6504, 6.9902),
      ]);
    final m = x.build('t', const []);
    expect(m.at(5, 9), Terrain.grass);
    expect(m.at(25, 25), Terrain.voidZone);
    expect(m.siteId, 't');
    expect(m.origin, const GeoPoint(43.651, 6.990));
  });
}
