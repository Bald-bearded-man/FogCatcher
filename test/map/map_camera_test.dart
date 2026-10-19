import 'dart:ui';
import 'package:fogcatcher/map/map_camera.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cellToScreen and screenToCell are inverse', () {
    final c = MapCamera(mapWidth: 200, mapHeight: 200)
      ..centerCells = const Offset(50, 60);
    const vp = Size(400, 800);
    final s = c.cellToScreen(const Offset(55, 62), vp);
    expect(c.screenToCell(s, vp).dx, closeTo(55, 1e-9));
    expect(c.screenToCell(s, vp).dy, closeTo(62, 1e-9));
  });
  test('centre cell maps to viewport centre', () {
    final c = MapCamera(mapWidth: 200, mapHeight: 200)
      ..centerCells = const Offset(10, 10);
    expect(
      c.cellToScreen(const Offset(10, 10), const Size(300, 600)),
      const Offset(150, 300),
    );
  });
  test('zoom clamps to the three levels', () {
    final c = MapCamera(mapWidth: 10, mapHeight: 10);
    c
      ..zoomIn()
      ..zoomIn()
      ..zoomIn();
    expect(c.pxPerCell, 16);
    c
      ..zoomOut()
      ..zoomOut()
      ..zoomOut();
    expect(c.pxPerCell, 6);
  });
  test('pan disables follow; follow ignored until recentre', () {
    final c = MapCamera(mapWidth: 100, mapHeight: 100)
      ..centerCells = const Offset(50, 50);
    c.panBy(const Offset(100, 0));
    expect(c.followPlayer, isFalse);
    final before = c.centerCells;
    c.follow(const Offset(10, 10));
    expect(c.centerCells, before);
    c.followPlayer = true;
    c.follow(const Offset(10, 10));
    expect(c.centerCells, const Offset(10, 10));
  });
  test('centre is clamped inside the map', () {
    final c = MapCamera(mapWidth: 100, mapHeight: 100)
      ..centerCells = const Offset(50, 50);
    c.panBy(const Offset(100000, 100000));
    expect(c.centerCells.dx, inInclusiveRange(0, 100));
    expect(c.centerCells.dy, inInclusiveRange(0, 100));
  });

  test('follow clamps a player cell beyond the map edge', () {
    final c = MapCamera(mapWidth: 100, mapHeight: 100);
    c.follow(const Offset(500, -20));
    expect(c.centerCells, const Offset(100, 0));
  });
}
