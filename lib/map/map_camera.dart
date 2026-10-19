import 'dart:math' as math;
import 'dart:ui';

/// Zoom levels in screen px per tilemap cell.
const mapZoomLevels = [6.0, 10.0, 16.0];

class MapCamera {
  MapCamera({
    required this.mapWidth,
    required this.mapHeight,
    this.zoomIndex = 1,
  }) : centerCells = Offset(mapWidth / 2, mapHeight / 2);

  final int mapWidth, mapHeight;
  int zoomIndex;
  Offset centerCells;
  bool followPlayer = true;

  double get pxPerCell => mapZoomLevels[zoomIndex];

  Offset cellToScreen(Offset cell, Size viewport) =>
      Offset(viewport.width / 2, viewport.height / 2) +
      (cell - centerCells) * pxPerCell;

  Offset screenToCell(Offset screen, Size viewport) =>
      centerCells +
      (screen - Offset(viewport.width / 2, viewport.height / 2)) / pxPerCell;

  Offset _clamp(Offset c) => Offset(
    c.dx.clamp(0.0, mapWidth.toDouble()),
    c.dy.clamp(0.0, mapHeight.toDouble()),
  );

  /// The map follows the finger, so the centre moves the opposite way.
  void panBy(Offset screenDelta) {
    followPlayer = false;
    centerCells = _clamp(centerCells - screenDelta / pxPerCell);
  }

  void zoomIn() =>
      zoomIndex = math.min(zoomIndex + 1, mapZoomLevels.length - 1);
  void zoomOut() => zoomIndex = math.max(zoomIndex - 1, 0);

  void follow(Offset playerCell) {
    if (followPlayer) centerCells = _clamp(playerCell);
  }
}
