import 'dart:typed_data';

import '../config/constants.dart';
import '../models/geo_point.dart';
import '../models/tile_map.dart';
import 'geo.dart';

/// One bit per fog cell, row-major (index = fy * width + fx).
class FogGrid {
  FogGrid({required this.width, required this.height, Uint8List? bits})
    : _bits = bits ?? Uint8List((width * height + 7) >> 3);

  factory FogGrid.forTileMap(TileMap map) => FogGrid(
    width: (map.width / fogCellTiles).ceil(),
    height: (map.height / fogCellTiles).ceil(),
  );

  /// Wrong-length input yields an empty grid instead of throwing.
  factory FogGrid.fromBytes(int width, int height, Uint8List bytes) {
    if (bytes.length != (width * height + 7) >> 3) {
      return FogGrid(width: width, height: height);
    }
    return FogGrid(
      width: width,
      height: height,
      bits: Uint8List.fromList(bytes),
    );
  }

  final int width, height;
  final Uint8List _bits;

  bool isRevealed(int fx, int fy) {
    if (fx < 0 || fy < 0 || fx >= width || fy >= height) return false;
    final i = fy * width + fx;
    return (_bits[i >> 3] & (1 << (i & 7))) != 0;
  }

  /// Reveals cells whose centre is within [radiusMeters] of [p]. True if any bit changed.
  bool reveal(
    GeoPoint p,
    LocalProjection proj,
    double fogCellMeters,
    double radiusMeters,
  ) {
    final m = proj.toMeters(p);
    final x0 = ((m.x - radiusMeters) / fogCellMeters).floor().clamp(
      0,
      width - 1,
    );
    final x1 = ((m.x + radiusMeters) / fogCellMeters).floor().clamp(
      0,
      width - 1,
    );
    final y0 = ((m.y - radiusMeters) / fogCellMeters).floor().clamp(
      0,
      height - 1,
    );
    final y1 = ((m.y + radiusMeters) / fogCellMeters).floor().clamp(
      0,
      height - 1,
    );
    final r2 = radiusMeters * radiusMeters;
    var changed = false;
    for (var fy = y0; fy <= y1; fy++) {
      for (var fx = x0; fx <= x1; fx++) {
        final dx = (fx + 0.5) * fogCellMeters - m.x;
        final dy = (fy + 0.5) * fogCellMeters - m.y;
        if (dx * dx + dy * dy > r2) continue;
        final i = fy * width + fx;
        final mask = 1 << (i & 7);
        if (_bits[i >> 3] & mask == 0) {
          _bits[i >> 3] |= mask;
          changed = true;
        }
      }
    }
    return changed;
  }

  Uint8List toBytes() => Uint8List.fromList(_bits);

  int get revealedCount {
    var n = 0;
    for (final b in _bits) {
      var v = b;
      while (v != 0) {
        n += v & 1;
        v >>= 1;
      }
    }
    return n;
  }
}
