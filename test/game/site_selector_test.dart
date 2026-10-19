import 'package:fogcatcher/config/constants.dart';
import 'package:fogcatcher/game/site_selector.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/site.dart';
import 'package:flutter_test/flutter_test.dart';

const park = Site(
  id: 'demo_park',
  name: 'P',
  center: GeoPoint(43.6524704, 6.9938705),
  radiusMeters: 490,
  bounds: GeoBounds(south: 0, west: 0, north: 0, east: 0),
);
const site = Site(
  id: 'test_site',
  name: 'T',
  center: GeoPoint(47.7839759, 1.0632297),
  radiusMeters: 1000,
  bounds: GeoBounds(south: 0, west: 0, north: 0, east: 0),
);

void main() {
  test('a point 1,130 m from the centre of a 1 km site picks it', () {
    const oldSite = Site(
      id: 'test_site',
      name: 'T',
      center: GeoPoint(47.7786, 1.0772),
      radiusMeters: 1000,
      bounds: GeoBounds(south: 0, west: 0, north: 0, east: 0),
    );
    expect(
      selectSite(const GeoPoint(47.783391, 1.063856), [park, oldSite], null),
      'test_site',
    );
  });
  test('a point inside the test site picks it', () {
    expect(
      selectSite(const GeoPoint(47.783391, 1.063856), [park, site], null),
      'test_site',
    );
  });
  test('picks the nearest of overlapping sites', () {
    const near = Site(
      id: 'near',
      name: 'N',
      center: GeoPoint(47.7786, 1.0800),
      radiusMeters: 1000,
      bounds: GeoBounds(south: 0, west: 0, north: 0, east: 0),
    );
    expect(
      selectSite(const GeoPoint(47.7786, 1.0799), [site, near], null),
      'near',
    );
  });
  test(
    'picks the site containing the point',
    () => expect(
      selectSite(const GeoPoint(47.784, 1.063), [park, site], null),
      'test_site',
    ),
  );
  test(
    'falls back to last active',
    () => expect(
      selectSite(const GeoPoint(48.85, 2.35), [park, site], 'test_site'),
      'test_site',
    ),
  );
  test(
    'falls back to default when nothing known',
    () => expect(selectSite(null, [park, site], null), defaultSiteId),
  );
  test(
    'ignores an unknown last active id',
    () => expect(selectSite(null, [park, site], 'gone'), defaultSiteId),
  );
}
