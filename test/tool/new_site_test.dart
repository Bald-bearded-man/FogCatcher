import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fogcatcher/game/geo.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/item.dart';
import 'package:fogcatcher/models/site.dart';
import 'package:fogcatcher/models/terrain.dart';
import 'package:fogcatcher/models/tile_map.dart';

import '../../tool/mapgen/mapgen.dart';
import '../../tool/mapgen/seed/spots.dart';
import '../../tool/src/site_content.dart';

void main() {
  group('photo names', () {
    test('slug keeps the order prefix, title drops it', () {
      expect(slugOf('01_Kite Lawn.PNG'), '01-kite-lawn');
      expect(titleOf('01_kite_lawn.png'), 'Kite Lawn');
      expect(titleOf('old-oak_tree.jpg'), 'Old Oak Tree');
      expect(titleOf('2024.jpg'), '2024');
    });
  });

  group('parseCsv', () {
    test('handles quotes, embedded commas, escaped quotes and CRLF', () {
      expect(
        parseCsv('file,title,text\r\na.png,"Hi, there","Say ""cheese"""\r\n\n'),
        [
          ['file', 'title', 'text'],
          ['a.png', 'Hi, there', 'Say "cheese"'],
        ],
      );
    });
    test('keeps newlines inside quoted fields', () {
      expect(parseCsv('a,"x\ny",z'), [
        ['a', 'x\ny', 'z'],
      ]);
    });
  });

  group('buildCatalogue', () {
    const files = ['2_bench.png', '1_fountain.jpg', '3_tree.webp'];
    test('without captions: filename order and titles, neutral text', () {
      final c = buildCatalogue(files);
      expect(c.map((p) => p.file), [
        '1_fountain.jpg',
        '2_bench.png',
        '3_tree.webp',
      ]);
      expect(c.map((p) => p.title), ['Fountain', 'Bench', 'Tree']);
      expect(c.map((p) => p.text), everyElement(defaultItemText));
    });
    test('captioned photos come first, in CSV order', () {
      final c = buildCatalogue(
        files,
        csv: 'file,title,text\n3_tree.webp,Old Tree,Very old.\n2_bench.png,,\n',
      );
      expect(c.map((p) => p.file), [
        '3_tree.webp',
        '2_bench.png',
        '1_fountain.jpg',
      ]);
      expect(c.first.title, 'Old Tree');
      expect(c.first.text, 'Very old.');
      expect(c[1].title, 'Bench'); // empty caption falls back
      expect(c[1].text, defaultItemText);
    });
    test('rejects a bad header, a missing photo and clashing slugs', () {
      expect(
        () => buildCatalogue(files, csv: 'name,title\n'),
        throwsFormatException,
      );
      expect(
        () => buildCatalogue(files, csv: 'file,title,text\nnope.png,A,B\n'),
        throwsFormatException,
      );
      expect(
        () => buildCatalogue(['a b.png', 'a_b.jpg']),
        throwsFormatException,
      );
    });
  });

  test('seededOrder is reproducible and keeps every element', () {
    final list = List.generate(12, (i) => i);
    expect(seededOrder(list, null), list);
    expect(seededOrder(list, 7), seededOrder(list, 7));
    expect(seededOrder(list, 7), isNot(list));
    expect(seededOrder(list, 7)..sort(), list);
  });

  group('siteJson', () {
    const center = GeoPoint(48.85, 2.29);
    test('bounds enclose the circle; boundary only when set', () {
      final j =
          jsonDecode(
                siteJson(
                  id: 'demo_park',
                  name: 'Demo park',
                  center: center,
                  radiusMeters: 300,
                ),
              )
              as Map<String, dynamic>;
      final site = Site.fromJson(j);
      expect(j.containsKey('boundary'), isFalse);
      final b = site.bounds;
      for (final edge in [
        GeoPoint(b.north, center.lng),
        GeoPoint(b.south, center.lng),
        GeoPoint(center.lat, b.east),
        GeoPoint(center.lat, b.west),
      ]) {
        expect(haversineMeters(center, edge), inInclusiveRange(300, 320));
      }
      final withBoundary =
          jsonDecode(
                siteJson(
                  id: 'demo_park',
                  name: 'Demo park',
                  center: center,
                  radiusMeters: 300,
                  boundary: 'way/42',
                ),
              )
              as Map<String, dynamic>;
      expect(boundaryOf(withBoundary), 'way/42');
    });
    test('site ids are lowercase snake_case', () {
      expect(validSiteId('demo_park'), isTrue);
      expect(validSiteId('Demo'), isFalse);
      expect(validSiteId('1park'), isFalse);
      expect(validSiteId('test-site'), isFalse);
    });
  });

  test('itemsJson pairs spot N with photo N and parses as items', () {
    final photos = buildCatalogue(['1_one.png', '2_two.png']);
    final json = itemsJson('test_site', [
      (id: 't01', point: const GeoPoint(1, 2)),
      (id: 't02', point: const GeoPoint(3, 4)),
    ], photos);
    final items = [
      for (final e
          in (jsonDecode(json) as Map<String, dynamic>)['items'] as List)
        Item.fromJson(e as Map<String, dynamic>),
    ];
    expect(items.map((i) => i.id), ['t01', 't02']);
    expect(items.last.image, 'assets/items/test_site-2-two.webp');
    expect(items.last.title, 'Two');
    expect(items.last.position, const GeoPoint(3, 4));
    expect(() => itemsJson('test_site', const [], photos), throwsArgumentError);
  });

  test('pickSpots keeps spacing, walkable cells and the circle', () {
    // 400 m grass square crossed by east-west paths every 40 m.
    const w = 100, h = 100;
    final cells = Uint8List(w * h)..fillRange(0, w * h, Terrain.grass.index);
    for (var y = 4; y < h; y += 10) {
      for (var x = 0; x < w; x++) {
        cells[y * w + x] = Terrain.path.index;
      }
    }
    const origin = GeoPoint(48.852, 2.29);
    final proj = LocalProjection(origin: origin, refLat: origin.lat);
    final center = proj.fromMeters(200, 200);
    final site = Site(
      id: 'demo_park',
      name: 'Demo park',
      center: center,
      radiusMeters: 190,
      bounds: GeoBounds(
        south: proj.fromMeters(0, 400).lat,
        west: origin.lng,
        north: origin.lat,
        east: proj.fromMeters(400, 0).lng,
      ),
    );
    final map = TileMap(
      siteId: site.id,
      width: w,
      height: h,
      cellMeters: 4,
      origin: origin,
      cells: cells,
    );
    final spots = pickSpots(
      site,
      map,
      const [],
      const {'elements': []},
      count: 8,
      spacing: 60,
    );
    expect(spots, hasLength(8));
    for (final s in spots) {
      expect(haversineMeters(center, s.point) + itemRadius, lessThan(190));
      final m = proj.toMeters(s.point);
      expect(map.at(m.x ~/ 4, m.y ~/ 4), Terrain.path);
      for (final o in spots.where((o) => o != s)) {
        expect(haversineMeters(s.point, o.point), greaterThanOrEqualTo(60));
      }
    }
    expect(spotId('demo_park', 0), 'd01');
    expect(spotId('demo_park', 11), 'd12');
  });
}
