import 'dart:ui' as ui;

import 'package:fogcatcher/map/map_camera.dart';
import 'package:fogcatcher/map/markers_painter.dart';
import 'package:fogcatcher/map/sprite_sheets.dart';
import 'package:fogcatcher/models/avatar.dart';
import 'package:fogcatcher/models/tileset_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_sheets.dart';

const _size = Size(200, 200);

MarkersPainter _painter(
  SpriteSheets sheets,
  Avatar avatar,
  double bob, {
  List<Chest<Offset>> chests = const [],
  bool withPlayer = true,
}) => MarkersPainter(
  camera: MapCamera(mapWidth: 40, mapHeight: 40),
  sheets: sheets,
  player: withPlayer ? const Offset(20, 20) : null, // viewport centre
  chests: chests,
  bob: AlwaysStoppedAnimation(bob),
  avatar: avatar,
);

/// Colour painted at the player marker's centre.
Future<ui.Color> _centre(MarkersPainter p) async {
  final rec = ui.PictureRecorder();
  p.paint(Canvas(rec), _size);
  final img = await rec.endRecording().toImage(200, 200);
  final bytes = (await img.toByteData())!;
  final o = (100 * 200 + 100) * 4;
  return ui.Color.fromARGB(
    bytes.getUint8(o + 3),
    bytes.getUint8(o),
    bytes.getUint8(o + 1),
    bytes.getUint8(o + 2),
  );
}

void main() {
  testWidgets('player marker draws the chosen avatar idle then bob frame', (
    t,
  ) async {
    await t.runAsync(() async {
      final sheets = await testSheets();
      final idle = _painter(sheets, Avatar.robot, 0);
      final bob = _painter(sheets, Avatar.robot, 0.75);
      expect([idle.playerFrame, bob.playerFrame], [10, 11]);
      expect(await _centre(idle), avatarColors[10]);
      expect(await _centre(bob), avatarColors[11]);
    });
  });

  testWidgets('chests draw the closed or open sprite', (t) async {
    await t.runAsync(() async {
      final sheets = await testSheets();
      Future<ui.Color> chest(bool opened) => _centre(
        _painter(
          sheets,
          Avatar.robot,
          0,
          chests: [(at: const Offset(20, 20), opened: opened)],
          withPlayer: false,
        ),
      );
      expect(await chest(false), spriteColors[spriteChestClosed]);
      expect(await chest(true), spriteColors[spriteChestOpen]);
    });
  });

  testWidgets('changing the avatar asks for a repaint', (t) async {
    final sheets = (await t.runAsync(testSheets))!;
    final a = _painter(sheets, Avatar.mage, 0);
    expect(a.shouldRepaint(_painter(sheets, Avatar.mage, 0)), isFalse);
    expect(a.shouldRepaint(_painter(sheets, Avatar.slime, 0)), isTrue);
  });
}
