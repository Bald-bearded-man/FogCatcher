import 'dart:typed_data';
import 'package:fogcatcher/game/fog_grid.dart';
import 'package:fogcatcher/game/geo.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/tile_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final proj = LocalProjection(
    origin: const GeoPoint(43.651, 6.990),
    refLat: 43.6505,
  );
  test(
    'starts fully hidden',
    () => expect(FogGrid(width: 10, height: 10).revealedCount, 0),
  );
  test('reveal opens cells within 30 m and not beyond', () {
    final g = FogGrid(width: 20, height: 20);
    final centre = proj.fromMeters(
      80,
      80,
    ); // shared corner of fog cells (4,4) and (5,5)
    expect(g.reveal(centre, proj, 16, 30), isTrue);
    expect(g.isRevealed(4, 4), isTrue); // centre (72,72): ~11 m
    expect(g.isRevealed(5, 5), isTrue);
    expect(g.isRevealed(7, 5), isFalse); // centre (120,88): ~41 m
  });
  test('reveal returns false when nothing changes', () {
    final g = FogGrid(width: 20, height: 20);
    final p = proj.fromMeters(80, 80);
    g.reveal(p, proj, 16, 30);
    expect(g.reveal(p, proj, 16, 30), isFalse);
  });
  test('points outside the grid do not throw', () {
    final g = FogGrid(width: 4, height: 4);
    expect(g.reveal(proj.fromMeters(-500, -500), proj, 16, 30), isFalse);
  });
  test('bytes round-trip', () {
    final g = FogGrid(width: 9, height: 3)
      ..reveal(proj.fromMeters(20, 20), proj, 16, 30);
    final back = FogGrid.fromBytes(9, 3, g.toBytes());
    expect(back.revealedCount, g.revealedCount);
  });
  test(
    'fromBytes with wrong length yields an empty grid',
    () => expect(FogGrid.fromBytes(9, 3, Uint8List(1)).revealedCount, 0),
  );
  test('isRevealed is false out of bounds', () {
    final g = FogGrid(width: 4, height: 4);
    expect(g.isRevealed(-1, 0), isFalse);
    expect(g.isRevealed(0, 4), isFalse);
  });
  test('forTileMap rounds up to whole fog cells', () {
    final map = TileMap(
      siteId: 's',
      width: 10,
      height: 9,
      cellMeters: 4,
      origin: const GeoPoint(43.651, 6.990),
      cells: Uint8List(90),
    );
    final g = FogGrid.forTileMap(map);
    expect((g.width, g.height), (3, 3));
  });
}
