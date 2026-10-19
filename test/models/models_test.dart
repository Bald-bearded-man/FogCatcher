import 'dart:typed_data';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/item.dart';
import 'package:fogcatcher/models/site.dart';
import 'package:fogcatcher/models/terrain.dart';
import 'package:fogcatcher/models/tile_map.dart';
import 'package:fogcatcher/models/tileset_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Item.fromJson defaults radius to 20', () {
    final i = Item.fromJson({
      'id': 'o01',
      'title': 't',
      'text': 'x',
      'image': 'a.png',
      'lat': 1,
      'lng': 2,
    });
    expect(i.radiusMeters, 20);
    expect(i.position, const GeoPoint(1, 2));
  });
  test('Item.fromJson honours an explicit radius', () {
    final i = Item.fromJson({
      'id': 'o',
      'title': 't',
      'text': 'x',
      'image': 'a',
      'lat': 1,
      'lng': 2,
      'radiusMeters': 35,
    });
    expect(i.radiusMeters, 35);
  });
  test('Site.fromJson parses centre, radius and bounds', () {
    final s = Site.fromJson({
      'id': 'demo_park',
      'name': 'Demo Park',
      'radiusMeters': 900,
      'center': {'lat': 43.65, 'lng': 6.99},
      'bounds': {'south': 1, 'west': 2, 'north': 3, 'east': 4},
    });
    expect(s.center, const GeoPoint(43.65, 6.99));
    expect(s.radiusMeters, 900);
    expect(s.bounds.north, 3);
  });
  test('GeoPoint equality and hash', () {
    expect(const GeoPoint(1, 2), const GeoPoint(1, 2));
    expect(const GeoPoint(1, 2).hashCode, const GeoPoint(1, 2).hashCode);
    expect(const GeoPoint(1, 2) == const GeoPoint(2, 1), isFalse);
  });
  test('TileMap json round-trip keeps cells and labels', () {
    final m = TileMap(
      siteId: 's',
      width: 3,
      height: 2,
      cellMeters: 4,
      origin: const GeoPoint(1, 2),
      cells: Uint8List.fromList([0, 1, 2, 3, 4, Terrain.voidZone.index]),
      labels: const [TileLabel('Piscine', 1, 1)],
    );
    final back = TileMap.fromJson(m.toJson());
    expect(back.cells, m.cells);
    expect(back.at(2, 1), Terrain.voidZone);
    expect(back.labels.single.text, 'Piscine');
    expect(back.origin, m.origin);
  });
  test('TileMap.at outside the grid is void', () {
    final m = TileMap(
      siteId: 's',
      width: 1,
      height: 1,
      cellMeters: 4,
      origin: const GeoPoint(0, 0),
      cells: Uint8List.fromList([0]),
    );
    expect(m.at(-1, 0), Terrain.voidZone);
    expect(m.at(0, 1), Terrain.voidZone);
  });
  test('every drawable terrain has a tile index within the sheet', () {
    for (final t in Terrain.values.where((t) => t != Terrain.voidZone)) {
      expect(terrainTileIndex[t], isNotNull);
    }
    expect(terrainTileIndex.containsKey(Terrain.voidZone), isFalse);
  });
}
