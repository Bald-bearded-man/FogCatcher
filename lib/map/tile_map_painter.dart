import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../config/theme.dart';
import '../models/terrain.dart';
import '../models/tile_map.dart';
import '../models/tileset_layout.dart';
import 'map_camera.dart';
import 'sprite_sheets.dart';

/// Inclusive-exclusive range of tilemap cells visible in [viewport], clamped to the map.
({int x0, int y0, int x1, int y1}) visibleCells(
  MapCamera camera,
  Size viewport,
) {
  final tl = camera.screenToCell(Offset.zero, viewport);
  final br = camera.screenToCell(
    Offset(viewport.width, viewport.height),
    viewport,
  );
  return (
    x0: math.max(0, tl.dx.floor()),
    y0: math.max(0, tl.dy.floor()),
    x1: math.min(camera.mapWidth, br.dx.ceil()),
    y1: math.min(camera.mapHeight, br.dy.ceil()),
  );
}

final _labelCache = <String, TextPainter>{};

TextPainter _label(String text) => _labelCache.putIfAbsent(
  text,
  () => TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        fontFamily: 'VT323',
        fontSize: 16,
        color: AppColors.paper,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(),
);

class TileMapPainter extends CustomPainter {
  TileMapPainter({
    required this.map,
    required this.camera,
    required this.sheets,
    required this.showLabels,
  }) : _zoom = camera.zoomIndex,
       _center = camera.centerCells;
  final TileMap map;
  final MapCamera camera;
  final SpriteSheets sheets;
  final bool showLabels;
  // Camera is mutable; snapshot its state for shouldRepaint.
  final int _zoom;
  final Offset _center;

  @override
  void paint(Canvas canvas, Size size) {
    // Black base covers void cells and everything outside the map.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF000000),
    );
    final v = visibleCells(camera, size);
    final px = camera.pxPerCell;
    final scale = px / tileSize;
    final transforms = <ui.RSTransform>[];
    final rects = <Rect>[];
    for (var y = v.y0; y < v.y1; y++) {
      for (var x = v.x0; x < v.x1; x++) {
        final t = map.at(x, y);
        if (t == Terrain.voidZone) continue;
        final idx = terrainTileIndex[t]!;
        final s = camera.cellToScreen(Offset(x.toDouble(), y.toDouble()), size);
        // Snapped to whole pixels so neighbouring tiles leave no seams.
        transforms.add(
          ui.RSTransform.fromComponents(
            rotation: 0,
            scale: scale,
            anchorX: 0,
            anchorY: 0,
            translateX: s.dx.roundToDouble(),
            translateY: s.dy.roundToDouble(),
          ),
        );
        rects.add(
          Rect.fromLTWH(
            (idx % tilesetColumns * tileSize).toDouble(),
            (idx ~/ tilesetColumns * tileSize).toDouble(),
            tileSize.toDouble(),
            tileSize.toDouble(),
          ),
        );
      }
    }
    if (transforms.isNotEmpty) {
      canvas.drawAtlas(
        sheets.tiles,
        transforms,
        rects,
        null,
        null,
        null,
        Paint()..filterQuality = FilterQuality.none,
      );
    }
    if (showLabels && camera.zoomIndex >= 1) _paintLabels(canvas, size, v);
  }

  void _paintLabels(
    Canvas canvas,
    Size size,
    ({int x0, int y0, int x1, int y1}) v,
  ) {
    final box = Paint()..color = AppColors.ink.withValues(alpha: 0.7);
    for (final l in map.labels) {
      if (l.x < v.x0 - 20 || l.x > v.x1 + 20 || l.y < v.y0 || l.y > v.y1) {
        continue;
      }
      final tp = _label(l.text);
      final s = camera.cellToScreen(Offset(l.x + 0.5, l.y + 0.5), size);
      final origin = s - Offset(tp.width / 2, tp.height / 2);
      canvas.drawRect((origin & tp.size).inflate(2), box);
      tp.paint(canvas, origin);
    }
  }

  @override
  bool shouldRepaint(TileMapPainter old) =>
      old.map != map ||
      old.sheets != sheets ||
      old.showLabels != showLabels ||
      old._zoom != _zoom ||
      old._center != _center;
}
