import '../config/constants.dart';
import '../models/geo_point.dart';
import '../models/site.dart';
import 'geo.dart';

/// Nearest site within radius + margin of [p] (as filterFix accepts), else
/// [lastActiveId] if known, else the default.
String selectSite(GeoPoint? p, List<Site> sites, String? lastActiveId) {
  if (p != null) {
    Site? best;
    var bestDistance = double.infinity;
    for (final s in sites) {
      final d = haversineMeters(p, s.center);
      if (d <= s.radiusMeters + siteMarginMeters && d < bestDistance) {
        best = s;
        bestDistance = d;
      }
    }
    if (best != null) return best.id;
  }
  if (lastActiveId != null && sites.any((s) => s.id == lastActiveId)) {
    return lastActiveId;
  }
  return defaultSiteId;
}
