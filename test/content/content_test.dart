import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:fogcatcher/config/constants.dart';
import 'package:fogcatcher/config/licenses.dart';
import 'package:fogcatcher/game/geo.dart';
import 'package:fogcatcher/models/item.dart';
import 'package:fogcatcher/models/site.dart';
import 'package:fogcatcher/models/terrain.dart';
import 'package:fogcatcher/models/tile_map.dart';
import 'package:fogcatcher/models/tileset_layout.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(String p) =>
    jsonDecode(File(p).readAsStringSync()) as Map<String, dynamic>;

({int width, int height}) _pngSize(String p) {
  final b = ByteData.sublistView(File(p).readAsBytesSync());
  return (width: b.getUint32(16), height: b.getUint32(20));
}

/// Mean HSV saturation of the opaque pixels in one sprite frame.
double _saturation(ByteData rgba, int imageWidth, int frame) {
  var sum = 0.0;
  var n = 0;
  for (var y = 0; y < tileSize; y++) {
    for (var x = frame * tileSize; x < (frame + 1) * tileSize; x++) {
      final o = (y * imageWidth + x) * 4;
      if (rgba.getUint8(o + 3) == 0) continue;
      final c = [rgba.getUint8(o), rgba.getUint8(o + 1), rgba.getUint8(o + 2)];
      final hi = c.reduce((a, b) => a > b ? a : b);
      final lo = c.reduce((a, b) => a < b ? a : b);
      sum += hi == 0 ? 0 : (hi - lo) / hi;
      n++;
    }
  }
  return sum / n;
}

void main() {
  final ids = (_json('assets/sites/index.json')['sites'] as List)
      .cast<String>();
  test('index lists the default site', () {
    expect(ids, isNotEmpty);
    expect(ids, contains(defaultSiteId));
  });
  for (final id in ids) {
    group(id, () {
      final site = Site.fromJson(_json('assets/sites/$id/site.json'));
      final items = (_json('assets/sites/$id/items.json')['items'] as List)
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList();
      final map = TileMap.fromJson(_json('assets/sites/$id/tilemap.json'));
      final proj = LocalProjection(origin: map.origin, refLat: site.center.lat);
      test('site and tilemap ids match the folder', () {
        expect(site.id, id);
        expect(map.siteId, id);
      });
      test('ships at least one item', () => expect(items, isNotEmpty));
      test(
        'ids are unique',
        () => expect(items.map((i) => i.id).toSet().length, items.length),
      );
      test('every item image referenced by items.json exists', () {
        for (final i in items) {
          expect(i.image, startsWith('assets/items/'), reason: i.id);
          expect(File(i.image).existsSync(), isTrue, reason: i.image);
        }
      });
      // A pack that ships a credits file must credit every photo it uses.
      final credits = File(itemCreditsAsset);
      test(
        'every item image has a credits row when credits ship',
        () {
          final files = creditEntries(
            credits.readAsStringSync(),
          ).map((e) => e.split('\n').first.replaceFirst('File: ', '')).toSet();
          for (final i in items) {
            expect(files, contains(i.image.split('/').last), reason: i.id);
          }
        },
        skip: credits.existsSync() ? false : 'no $itemCreditsAsset',
      );
      test(
        'every bundled item lies outside void cells and inside its site',
        () {
          for (final i in items) {
            expect(
              haversineMeters(site.center, i.position) + i.radiusMeters,
              lessThanOrEqualTo(site.radiusMeters),
              reason: i.id,
            );
            final m = proj.toMeters(i.position);
            expect(
              map.at(m.x ~/ map.cellMeters, m.y ~/ map.cellMeters),
              isNot(Terrain.voidZone),
              reason: i.id,
            );
          }
        },
      );
      test('items are at least 60 m apart', () {
        for (var a = 0; a < items.length; a++) {
          for (var b = a + 1; b < items.length; b++) {
            expect(
              haversineMeters(items[a].position, items[b].position),
              greaterThanOrEqualTo(60),
            );
          }
        }
      });
    });
  }
  test('tile sheets match tileset_layout.dart', () {
    final tiles = _pngSize('assets/tiles/tileset.png');
    final maxTile = terrainTileIndex.values.reduce((a, b) => a > b ? a : b);
    expect(tiles.width, tilesetColumns * tileSize);
    expect(
      tiles.height,
      greaterThanOrEqualTo((maxTile ~/ tilesetColumns + 1) * tileSize),
    );
    final sprites = _pngSize('assets/tiles/sprites.png');
    expect(sprites.width, (spriteSparkleFirst + spriteSparkleCount) * tileSize);
    expect(sprites.height, tileSize);
  });
  group('chest sprites', () {
    late ByteData rgba;
    late int width;
    setUpAll(() async {
      final codec = await ui.instantiateImageCodec(
        File('assets/tiles/sprites.png').readAsBytesSync(),
      );
      final image = (await codec.getNextFrame()).image;
      width = image.width;
      rgba = (await image.toByteData())!;
    });

    test('closed chest is greyer than the open one', () {
      // Unfound crates must read duller on the map than found ones.
      expect(
        _saturation(rgba, width, spriteChestClosed),
        lessThan(_saturation(rgba, width, spriteChestOpen) * 0.75),
      );
    });

    test('closed chest has no dark slit under the lid', () {
      int px(int x, int y) =>
          rgba.getUint32((y * width + spriteChestClosed * tileSize + x) * 4);
      final outline = px(0, 3);
      // A gap in the outline colour between lid and body reads as ajar.
      for (var y = 9; y < 12; y++) {
        for (var x = 3; x < 13; x++) {
          expect(px(x, y), isNot(outline), reason: 'pixel ($x, $y)');
        }
      }
    });
  });
}
