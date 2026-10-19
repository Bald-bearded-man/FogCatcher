import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/terrain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/mapgen/classify.dart';
import '../../tool/mapgen/osm.dart';

void main() {
  test('golf, archery, private and farmland are void', () {
    expect(isVoid({'leisure': 'golf_course'}), isTrue);
    expect(isVoid({'golf': 'driving_range'}), isTrue);
    expect(isVoid({'leisure': 'pitch', 'sport': 'archery'}), isTrue);
    expect(isVoid({'amenity': 'parking', 'access': 'private'}), isTrue);
    expect(isVoid({'landuse': 'farmland'}), isTrue);
    expect(isVoid({'leisure': 'pitch', 'sport': 'tennis'}), isFalse);
  });
  test(
    'golf features get a void stroke: corridor for holes, buffer for areas',
    () {
      expect(golfVoidStroke({'golf': 'hole'}), 60);
      for (final g in [
        'tee',
        'green',
        'bunker',
        'fairway',
        'rough',
        'driving_range',
      ]) {
        expect(golfVoidStroke({'golf': g}), 20, reason: g);
      }
      expect(golfVoidStroke({'golf': 'clubhouse'}), isNull);
      expect(golfVoidStroke({'highway': 'path'}), isNull);
    },
  );
  test('guest-only pools stay water, not void', () {
    const pool = {'leisure': 'swimming_pool', 'access': 'private'};
    expect(isVoid(pool), isFalse);
    expect(classify(pool), Terrain.water);
  });
  test('classify maps tags to terrain', () {
    expect(classify({'building': 'yes'}), Terrain.building);
    expect(classify({'highway': 'footway'}), Terrain.path);
    expect(classify({'highway': 'service'}), Terrain.path);
    expect(classify({'highway': 'residential'}), Terrain.road);
    expect(classify({'amenity': 'parking'}), Terrain.parking);
    expect(classify({'leisure': 'pitch'}), Terrain.court);
    expect(classify({'natural': 'beach'}), Terrain.sand);
    expect(classify({'landuse': 'forest'}), Terrain.wood);
    expect(classify({'natural': 'water'}), Terrain.water);
    expect(classify({'shop': 'bakery'}), isNull);
    expect(strokeWidth(Terrain.road), 7);
    expect(strokeWidth(Terrain.path), 3);
    expect(strokeWidth(Terrain.wood), isNull);
  });
  test('stitchRings joins pieces sharing end nodes, reversed or not', () {
    const a = GeoPoint(0, 0), b = GeoPoint(0, 1), c = GeoPoint(1, 1);
    const d = GeoPoint(1, 0);
    final rings = stitchRings([
      [a, b],
      [c, b], // reversed piece
      [c, d, a],
    ]);
    expect(rings, hasLength(1));
    expect(rings.single.first, rings.single.last);
    expect(rings.single.toSet(), {a, b, c, d});
  });
  test(
    'parseFeatures builds multipolygons and treats closed highways as lines',
    () {
      Map<String, double> p(double lat, double lon) => {'lat': lat, 'lon': lon};
      final square = [p(0, 0), p(0, 1), p(1, 1), p(1, 0), p(0, 0)];
      final f = parseFeatures({
        'elements': [
          {
            'type': 'way',
            'id': 1,
            'tags': {'highway': 'service'},
            'geometry': square,
          },
          {
            'type': 'way',
            'id': 2,
            'tags': {'building': 'yes'},
            'geometry': square,
          },
          {
            'type': 'relation',
            'id': 3,
            'tags': {'type': 'multipolygon', 'natural': 'wood'},
            'members': [
              {
                'type': 'way',
                'role': 'outer',
                'geometry': square.sublist(0, 3),
              },
              {'type': 'way', 'role': 'outer', 'geometry': square.sublist(2)},
            ],
          },
        ],
      });
      expect(f.map((e) => e.isArea), [false, true, true]);
      expect(f[2].id, 'relation/3');
      expect(f[2].outers.single, hasLength(5));
    },
  );
}
