import 'package:fogcatcher/config/constants.dart' as app;
import 'package:fogcatcher/game/geo.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/site.dart';
import 'package:fogcatcher/models/terrain.dart';
import 'package:fogcatcher/models/tile_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/mapgen/mapgen.dart';
import '../../tool/mapgen/osm.dart';
import '../../tool/mapgen/overpass.dart';

void main() {
  // 400 m square, circle boundary large enough to keep everything playable.
  const site = Site(
    id: 'test_site',
    name: 'Test site',
    center: GeoPoint(43.6500, 6.9900),
    radiusMeters: 300,
    bounds: GeoBounds(
      south: 43.6482,
      west: 6.9875,
      north: 43.6518,
      east: 6.9925,
    ),
  );
  final proj = LocalProjection(
    origin: GeoPoint(site.bounds.north, site.bounds.west),
    refLat: site.center.lat,
  );
  GeoPoint at(double x, double y) => proj.fromMeters(x, y);

  test('golf=hole lines void a 60 m corridor, paths included', () {
    final map = generate(site, [
      OsmFeature(
        id: 'way/1',
        tags: const {'highway': 'footway'},
        line: [at(0, 200), at(400, 200)],
      ),
      OsmFeature(
        id: 'way/2',
        tags: const {'golf': 'hole'},
        line: [at(200, 0), at(200, 400)],
      ),
    ], const []);
    Terrain cell(double x, double y) =>
        map.at(x ~/ map.cellMeters, y ~/ map.cellMeters);
    expect(cell(200, 100), Terrain.voidZone);
    expect(cell(226, 100), Terrain.voidZone); // inside the 30 m half-width
    expect(cell(240, 100), Terrain.grass);
    expect(cell(200, 201), Terrain.voidZone); // footway crossing the hole
    expect(cell(100, 201), Terrain.path);
  });

  test('golf areas are voided with a 10 m buffer', () {
    final map = generate(site, [
      OsmFeature(
        id: 'way/3',
        tags: const {'golf': 'green'},
        outers: [
          [
            at(150, 150),
            at(250, 150),
            at(250, 250),
            at(150, 250),
            at(150, 150),
          ],
        ],
      ),
    ], const []);
    Terrain cell(double x, double y) =>
        map.at(x ~/ map.cellMeters, y ~/ map.cellMeters);
    expect(cell(200, 200), Terrain.voidZone);
    expect(cell(142, 200), Terrain.voidZone); // 8 m outside the edge
    expect(cell(130, 200), Terrain.grass);
  });

  test('tool cell size matches the app', () {
    expect(tileCellMeters, app.tileCellMeters);
  });

  group('boundary', () {
    test('is optional and must be way/<id> or relation/<id>', () {
      expect(boundaryOf({'id': 'test_site'}), isNull);
      expect(boundaryOf({'boundary': 'relation/42'}), 'relation/42');
      expect(boundaryOf({'boundary': 'way/7'}), 'way/7');
      for (final bad in [42, 'node/1', 'relation/0', 'way/x', 'relation/42 ']) {
        expect(() => boundaryOf({'boundary': bad}), throwsFormatException);
      }
    });

    final square = [at(100, 100), at(300, 100), at(300, 300), at(100, 300)];
    final boundary = OsmFeature(
      id: 'relation/42',
      tags: const {'type': 'multipolygon', 'leisure': 'park'},
      outers: [
        [...square, square.first],
      ],
    );
    Terrain cell(TileMap map, double x, double y) =>
        map.at(x ~/ map.cellMeters, y ~/ map.cellMeters);

    test('voids everything outside the relation instead of the circle', () {
      final map = generate(site, [boundary], const [], boundary: 'relation/42');
      expect(cell(map, 200, 200), Terrain.grass);
      expect(cell(map, 50, 200), Terrain.voidZone); // inside the circle
      expect(
        cell(generate(site, [boundary], const []), 50, 200),
        Terrain.grass,
      );
    });

    test('accepts a closed way', () {
      final way = OsmFeature(
        id: 'way/7',
        tags: const {'leisure': 'park'},
        outers: boundary.outers,
      );
      final map = generate(site, [way], const [], boundary: 'way/7');
      expect(cell(map, 200, 200), Terrain.grass);
      expect(cell(map, 50, 200), Terrain.voidZone);
    });

    test('fails clearly when the boundary is not in the OSM data', () {
      expect(
        () => generate(site, [boundary], const [], boundary: 'relation/7'),
        throwsStateError,
      );
    });
  });

  test('OSM API data converts to the Overpass geometry shape', () {
    final converted = fromOsmApi({
      'elements': [
        {'type': 'node', 'id': 1, 'lat': 48.0, 'lon': 2.0},
        {'type': 'node', 'id': 2, 'lat': 48.001, 'lon': 2.0},
        {'type': 'node', 'id': 3, 'lat': 48.001, 'lon': 2.001},
        {
          'type': 'way',
          'id': 10,
          'nodes': [1, 2, 3, 1],
          'tags': {'leisure': 'park'},
        },
        {
          'type': 'way',
          'id': 11,
          'nodes': [1, 2],
          'tags': {'note': 'untagged for us'},
        },
        {
          'type': 'relation',
          'id': 20,
          'tags': {'type': 'multipolygon', 'leisure': 'garden'},
          'members': [
            {'type': 'way', 'ref': 10, 'role': 'outer'},
            {'type': 'way', 'ref': 99, 'role': 'outer'}, // outside the bbox
          ],
        },
      ],
    });
    final features = parseFeatures(converted);
    expect(features.map((f) => f.id), ['way/10', 'relation/20']);
    expect(features.first.outers.single, hasLength(4));
    expect(features.last.outers.single.first, const GeoPoint(48.0, 2.0));
  });

  test('OSM API fallback refuses boxes over 0.25 deg²', () {
    checkOsmApiArea(site.bounds); // small box passes
    expect(
      () => checkOsmApiArea(
        const GeoBounds(south: 48, west: 2, north: 48.6, east: 2.5),
      ),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', contains('0.25')),
      ),
    );
  });
}
