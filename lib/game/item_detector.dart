import '../models/geo_point.dart';
import '../models/item.dart';
import 'geo.dart';

/// Unfound items within their radius of [p], in items order.
List<Item> detectItems(GeoPoint p, List<Item> items, Set<String> found) => [
  for (final i in items)
    if (!found.contains(i.id) &&
        haversineMeters(p, i.position) <= i.radiusMeters)
      i,
];
