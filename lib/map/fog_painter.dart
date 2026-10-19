import 'package:flutter/widgets.dart';

import '../config/constants.dart';
import '../models/tile_map.dart';
import 'map_camera.dart';
import 'tile_map_painter.dart';

/// Fog query decoupled from FogGrid: (fx, fy) -> revealed.
typedef FogQuery = bool Function(int fx, int fy);

class FogPainter extends CustomPainter {
  FogPainter({
    required this.map,
    required this.camera,
    required this.isRevealed,
  });
  final TileMap map;
  final MapCamera camera;
  final FogQuery isRevealed;

  bool _touchesRevealed(int fx, int fy) {
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if ((dx != 0 || dy != 0) && isRevealed(fx + dx, fy + dy)) return true;
      }
    }
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final v = visibleCells(camera, size);
    final px = camera.pxPerCell;
    final fogPx = px * fogCellTiles;
    final half = px / 2;
    final path = Path();
    for (var fy = v.y0 ~/ fogCellTiles; fy * fogCellTiles < v.y1; fy++) {
      for (var fx = v.x0 ~/ fogCellTiles; fx * fogCellTiles < v.x1; fx++) {
        if (isRevealed(fx, fy)) continue;
        final tl = camera.cellToScreen(
          Offset(
            (fx * fogCellTiles).toDouble(),
            (fy * fogCellTiles).toDouble(),
          ),
          size,
        );
        final left = tl.dx.roundToDouble(), top = tl.dy.roundToDouble();
        if (!_touchesRevealed(fx, fy)) {
          path.addRect(Rect.fromLTWH(left, top, fogPx, fogPx));
          continue;
        }
        // Retro edge: checkerboard of black squares.
        final n = fogCellTiles * 2;
        for (var j = 0; j < n; j++) {
          for (var i = 0; i < n; i++) {
            if ((i + j).isEven) continue;
            path.addRect(
              Rect.fromLTWH(left + i * half, top + j * half, half, half),
            );
          }
        }
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF000000)
        ..isAntiAlias = false,
    );
  }

  @override
  // isRevealed is a closure over mutable fog state, so it can't be compared;
  // the layer sits in a RepaintBoundary and only repaints on rebuild.
  bool shouldRepaint(FogPainter old) => true;
}
