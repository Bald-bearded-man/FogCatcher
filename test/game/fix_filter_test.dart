import 'package:fogcatcher/game/fix_filter.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/position_fix.dart';
import 'package:fogcatcher/models/site.dart';
import 'package:flutter_test/flutter_test.dart';

const site = Site(
  id: 's',
  name: 'S',
  center: GeoPoint(43.6525, 6.9939),
  radiusMeters: 490,
  bounds: GeoBounds(south: 43.6489, west: 6.9889, north: 43.6560, east: 6.9988),
);
PositionFix fix(GeoPoint p, double acc) =>
    PositionFix(point: p, accuracyMeters: acc, time: DateTime.utc(2030, 6, 1));

void main() {
  test(
    'accepts an accurate fix inside the site',
    () => expect(
      filterFix(fix(const GeoPoint(43.6525, 6.9939), 10), site),
      FixVerdict.accepted,
    ),
  );
  test(
    'rejects a fix with accuracy worse than 50 m',
    () => expect(
      filterFix(fix(const GeoPoint(43.6525, 6.9939), 51), site),
      FixVerdict.inaccurate,
    ),
  );
  test(
    'accepts up to 50 m accuracy for display',
    () => expect(
      filterFix(fix(const GeoPoint(43.6525, 6.9939), 50), site),
      FixVerdict.accepted,
    ),
  );
  test('filterFix rejects fixes beyond site radius + margin', () {
    expect(
      filterFix(fix(const GeoPoint(47.7786, 1.0772), 5), site),
      FixVerdict.outsideSite,
    ); // another region
    expect(
      filterFix(fix(const GeoPoint(43.6525 + 0.0065, 6.9939), 5), site),
      FixVerdict.outsideSite,
    ); // ~723 m north
  });
  test(
    'accepts inside the 200 m margin',
    () => expect(
      filterFix(fix(const GeoPoint(43.6525 + 0.0054, 6.9939), 5), site),
      FixVerdict.accepted,
    ),
  ); // ~600 m
}
