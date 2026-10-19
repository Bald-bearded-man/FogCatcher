import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fogcatcher/game/geo.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/site.dart';
import 'package:fogcatcher/models/terrain.dart';
import 'package:fogcatcher/models/tile_map.dart';

typedef _Pt = ({double x, double y});

/// Paints OSM geometry onto a terrain grid; later writes overwrite earlier ones.
class Rasterizer {
  Rasterizer({
    required GeoBounds bounds,
    required double refLat,
    required this.cellMeters,
  }) : origin = GeoPoint(bounds.north, bounds.west),
       projection = LocalProjection(
         origin: GeoPoint(bounds.north, bounds.west),
         refLat: refLat,
       ) {
    final se = projection.toMeters(GeoPoint(bounds.south, bounds.east));
    width = (se.x / cellMeters).ceil();
    height = (se.y / cellMeters).ceil();
    cells = Uint8List(width * height)
      ..fillRange(0, width * height, Terrain.grass.index);
  }

  final double cellMeters;
  final GeoPoint origin;
  final LocalProjection projection;
  late final int width;
  late final int height;
  late final Uint8List cells;

  void _set(int x, int y, Terrain t) {
    if (x >= 0 && y >= 0 && x < width && y < height) {
      cells[y * width + x] = t.index;
    }
  }

  _Pt _centre(int x, int y) =>
      (x: (x + 0.5) * cellMeters, y: (y + 0.5) * cellMeters);

  List<_Pt> _project(List<GeoPoint> ring) => [
    for (final p in ring) projection.toMeters(p),
  ];

  /// Even-odd scanline fill at cell-centre rows.
  void fillPolygon(
    List<GeoPoint> outer,
    List<List<GeoPoint>> holes,
    Terrain t,
  ) {
    final rings = [_project(outer), for (final h in holes) _project(h)];
    for (var y = 0; y < height; y++) {
      final cy = (y + 0.5) * cellMeters;
      final xs = <double>[];
      for (final ring in rings) {
        _crossings(ring, cy, xs);
      }
      xs.sort();
      for (var i = 0; i + 1 < xs.length; i += 2) {
        final from = math.max(0, (xs[i] / cellMeters - 0.5).ceil());
        final to = math.min(
          width - 1,
          (xs[i + 1] / cellMeters - 0.5).ceil() - 1,
        );
        for (var x = from; x <= to; x++) {
          _set(x, y, t);
        }
      }
    }
  }

  static void _crossings(List<_Pt> ring, double cy, List<double> out) {
    for (var i = 0; i < ring.length; i++) {
      final a = ring[i], b = ring[(i + 1) % ring.length];
      if ((a.y <= cy) != (b.y <= cy)) {
        out.add(a.x + (cy - a.y) * (b.x - a.x) / (b.y - a.y));
      }
    }
  }

  /// Samples every half cell and paints cells whose centre is near a sample.
  void strokeLine(List<GeoPoint> line, double widthMeters, Terrain t) {
    final pts = _project(line);
    final reach = widthMeters / 2 + cellMeters / 2;
    for (var i = 0; i + 1 < pts.length; i++) {
      final a = pts[i], b = pts[i + 1];
      final len = math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2));
      final n = math.max(1, (len / (cellMeters / 2)).ceil());
      for (var k = 0; k <= n; k++) {
        final f = k / n;
        _disc(a.x + (b.x - a.x) * f, a.y + (b.y - a.y) * f, reach, t);
      }
    }
  }

  void _disc(double px, double py, double reach, Terrain t) {
    final x0 = ((px - reach) / cellMeters).floor();
    final x1 = ((px + reach) / cellMeters).floor();
    final y0 = ((py - reach) / cellMeters).floor();
    final y1 = ((py + reach) / cellMeters).floor();
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        final c = _centre(x, y);
        final dx = c.x - px, dy = c.y - py;
        if (dx * dx + dy * dy <= reach * reach) _set(x, y, t);
      }
    }
  }

  void voidOutsideCircle(GeoPoint center, double radiusMeters) {
    final c = projection.toMeters(center);
    _voidWhere((p) {
      final dx = p.x - c.x, dy = p.y - c.y;
      return dx * dx + dy * dy > radiusMeters * radiusMeters;
    });
  }

  void voidOutsidePolygon(List<GeoPoint> outer) {
    final ring = _project(outer);
    _voidWhere((p) => !_inside(ring, p));
  }

  static bool _inside(List<_Pt> ring, _Pt p) {
    final xs = <double>[];
    _crossings(ring, p.y, xs);
    return xs.where((x) => x < p.x).length.isOdd;
  }

  void _voidWhere(bool Function(_Pt) test) {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (test(_centre(x, y))) _set(x, y, Terrain.voidZone);
      }
    }
  }

  TileMap build(String siteId, List<TileLabel> labels) => TileMap(
    siteId: siteId,
    width: width,
    height: height,
    cellMeters: cellMeters,
    origin: origin,
    cells: Uint8List.fromList(cells),
    labels: labels,
  );
}
