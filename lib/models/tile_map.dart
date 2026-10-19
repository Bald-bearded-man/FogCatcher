import 'dart:convert';
import 'dart:typed_data';

import 'geo_point.dart';
import 'terrain.dart';

class TileLabel {
  const TileLabel(this.text, this.x, this.y);
  final String text;
  final int x, y;
}

/// Row-major grid, row 0 = north edge, x grows east. One byte per cell = Terrain.index.
class TileMap {
  TileMap({
    required this.siteId,
    required this.width,
    required this.height,
    required this.cellMeters,
    required this.origin,
    required this.cells,
    this.labels = const [],
  });
  final String siteId;
  final int width, height;
  final double cellMeters;
  final GeoPoint origin; // north-west corner of cell (0,0)
  final Uint8List cells;
  final List<TileLabel> labels;

  Terrain at(int x, int y) => (x < 0 || y < 0 || x >= width || y >= height)
      ? Terrain.voidZone
      : Terrain.values[cells[y * width + x]];

  factory TileMap.fromJson(Map<String, dynamic> j) => TileMap(
    siteId: j['siteId'] as String,
    width: j['width'] as int,
    height: j['height'] as int,
    cellMeters: (j['cellMeters'] as num).toDouble(),
    origin: GeoPoint.fromJson(j['origin'] as Map<String, dynamic>),
    cells: base64Decode(j['terrain'] as String),
    labels: [
      for (final l in (j['labels'] as List<dynamic>? ?? const []))
        TileLabel(
          (l as Map<String, dynamic>)['text'] as String,
          l['x'] as int,
          l['y'] as int,
        ),
    ],
  );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'siteId': siteId,
    'width': width,
    'height': height,
    'cellMeters': cellMeters,
    'origin': {'lat': origin.lat, 'lng': origin.lng},
    'terrain': base64Encode(cells),
    'labels': [
      for (final l in labels) {'text': l.text, 'x': l.x, 'y': l.y},
    ],
  };
}
