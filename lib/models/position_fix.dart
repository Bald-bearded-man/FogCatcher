// coverage:ignore-file (declarations only)
import 'geo_point.dart';

class PositionFix {
  const PositionFix({
    required this.point,
    required this.accuracyMeters,
    required this.time,
    this.simulated = false,
  });
  final GeoPoint point;
  final double accuracyMeters;
  final DateTime time;
  final bool simulated;
}
