import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fogcatcher/game/geo.dart';
import 'package:fogcatcher/map/sprite_sheets.dart';
import 'package:fogcatcher/models/avatar.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/terrain.dart';
import 'package:fogcatcher/models/tile_map.dart';
import 'package:fogcatcher/models/tileset_layout.dart';

Future<ui.Image> _strip(List<ui.Color> colors, int columns) async {
  final rows = (colors.length + columns - 1) ~/ columns;
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec);
  for (var i = 0; i < colors.length; i++) {
    canvas.drawRect(
      ui.Rect.fromLTWH(
        (i % columns * tileSize).toDouble(),
        (i ~/ columns * tileSize).toDouble(),
        tileSize.toDouble(),
        tileSize.toDouble(),
      ),
      ui.Paint()..color = colors[i],
    );
  }
  return rec.endRecording().toImage(columns * tileSize, rows * tileSize);
}

/// One solid colour per avatar frame, so a pixel probe tells frames apart.
final avatarColors = [
  for (var i = 0; i < Avatar.frameCount; i++)
    ui.Color.fromARGB(255, 255 - i * 10, i * 12, 128 + i * 6),
];

/// One solid colour per sprite frame.
const spriteColors = [
  ui.Color(0xFFF26530), // player
  ui.Color(0xFF6D5AA6), // chest closed
  ui.Color(0xFFFFD54F), // chest open
  ui.Color(0xFFFFFFFF),
  ui.Color(0xFFFFFFFF),
  ui.Color(0xFFFFFFFF),
  ui.Color(0xFFFFFFFF),
];

/// In-memory 16 px solid-colour sheets. In widget tests call inside `tester.runAsync`.
Future<SpriteSheets> testSheets() async {
  const tileColors = [
    ui.Color(0xFF4CAF50), // grass
    ui.Color(0xFF2E7D32), // wood
    ui.Color(0xFFE6D690), // sand
    ui.Color(0xFFD2691E), // court
    ui.Color(0xFF9E9E9E), // parking
    ui.Color(0xFF616161), // road
    ui.Color(0xFFBCAAA4), // path
    ui.Color(0xFF1E88E5), // water
    ui.Color(0xFF8D6E63), // building
  ];
  return SpriteSheets(
    tiles: await _strip(tileColors, tilesetColumns),
    sprites: await _strip(spriteColors, spriteColors.length),
    avatars: await _strip(avatarColors, avatarColors.length),
  );
}

const testMapOrigin = GeoPoint(44.0, 7.0);

LocalProjection testProjection() =>
    LocalProjection(origin: testMapOrigin, refLat: 44.0);

/// 40x40 grass, water square at (22..27, 5..10), void band on rows 30..33.
TileMap testMap() {
  final cells = Uint8List(40 * 40)..fillRange(0, 40 * 40, Terrain.grass.index);
  for (var y = 5; y < 11; y++) {
    for (var x = 22; x < 28; x++) {
      cells[y * 40 + x] = Terrain.water.index;
    }
  }
  for (var y = 30; y < 34; y++) {
    for (var x = 0; x < 40; x++) {
      cells[y * 40 + x] = Terrain.voidZone.index;
    }
  }
  return TileMap(
    siteId: 'test',
    width: 40,
    height: 40,
    cellMeters: 4,
    origin: testMapOrigin,
    cells: cells,
    labels: const [TileLabel('Lac', 24, 8)],
  );
}
