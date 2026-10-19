import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../config/theme.dart';
import '../models/avatar.dart';
import '../models/tileset_layout.dart';
import 'map_camera.dart';
import 'sprite_sheets.dart';

/// An item crate at [at]; [opened] once found.
typedef Chest<T> = ({T at, bool opened});

class MarkersPainter extends CustomPainter {
  MarkersPainter({
    required this.camera,
    required this.sheets,
    required this.player,
    required this.chests,
    required this.bob,
    this.avatar = Avatar.fallback,
    this.pin,
  }) : _zoom = camera.zoomIndex,
       _center = camera.centerCells,
       super(repaint: bob);
  final MapCamera camera;
  final SpriteSheets sheets;
  final Offset? player; // tilemap cell coordinates
  final List<Chest<Offset>> chests; // tilemap cell coordinates
  final Offset? pin; // site centre while there is no accepted fix
  final Animation<double> bob; // 2-frame bob, repaints only this layer
  final Avatar avatar;
  final int _zoom;
  final Offset _center;

  /// Avatar frame the player marker draws right now.
  @visibleForTesting
  int get playerFrame => avatar.frame(bob.value >= 0.5 ? 1 : 0);

  void _sprite(
    Canvas canvas,
    Size size,
    ui.Image sheet,
    Offset cell,
    int frame,
  ) {
    final spritePx = camera.pxPerCell * 3;
    final c = camera.cellToScreen(cell, size);
    final dst = Rect.fromCenter(center: c, width: spritePx, height: spritePx);
    final src = Rect.fromLTWH(
      (frame * tileSize).toDouble(),
      0,
      tileSize.toDouble(),
      tileSize.toDouble(),
    );
    canvas.drawImageRect(
      sheet,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  // Blue square head on a stem; the tip sits on the site centre.
  void _drawPin(Canvas canvas, Size size) {
    final u = camera.pxPerCell;
    final tip = camera.cellToScreen(pin!, size);
    final head = Rect.fromLTWH(tip.dx - 1.5 * u, tip.dy - 5 * u, 3 * u, 3 * u);
    final stem = Rect.fromLTWH(tip.dx - 0.5 * u, tip.dy - 2 * u, u, 2 * u);
    final border = Paint()..color = AppColors.ink;
    final fill = Paint()..color = AppColors.primary;
    canvas.drawRect(stem.inflate(u / 2), border);
    canvas.drawRect(head.inflate(u / 2), border);
    canvas.drawRect(stem, fill);
    canvas.drawRect(head, fill);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in chests) {
      final frame = c.opened ? spriteChestOpen : spriteChestClosed;
      _sprite(canvas, size, sheets.sprites, c.at, frame);
    }
    if (pin != null) _drawPin(canvas, size);
    // The avatar frames carry the bob, so the marker no longer hops.
    if (player != null) {
      _sprite(canvas, size, sheets.avatars, player!, playerFrame);
    }
  }

  @override
  bool shouldRepaint(MarkersPainter old) =>
      old.sheets != sheets ||
      old.player != player ||
      old.avatar != avatar ||
      old.pin != pin ||
      !listEquals(old.chests, chests) ||
      old._zoom != _zoom ||
      old._center != _center;
}
