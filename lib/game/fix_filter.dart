import '../config/constants.dart';
import '../models/position_fix.dart';
import '../models/site.dart';
import 'geo.dart';

enum FixVerdict { accepted, inaccurate, outsideSite }

FixVerdict filterFix(PositionFix fix, Site site) {
  if (fix.accuracyMeters > maxDisplayAccuracyMeters) {
    return FixVerdict.inaccurate;
  }
  if (haversineMeters(fix.point, site.center) >
      site.radiusMeters + siteMarginMeters) {
    return FixVerdict.outsideSite;
  }
  return FixVerdict.accepted;
}
