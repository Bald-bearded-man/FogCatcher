import 'package:fogcatcher/services/content_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _MapBundle extends CachingAssetBundle {
  _MapBundle(this.files);
  final Map<String, String> files;
  @override
  Future<ByteData> load(String key) async {
    final s = files[key];
    if (s == null) throw FlutterError('missing $key');
    return ByteData.sublistView(Uint8List.fromList(s.codeUnits));
  }
}

void main() {
  test('loads every site listed in index.json', () async {
    const site =
        '{"id":"t","name":"T","center":{"lat":1,"lng":2},"radiusMeters":100,'
        '"bounds":{"south":0,"west":0,"north":1,"east":1}}';
    const items =
        '{"items":[{"id":"i1","title":"A","text":"B","image":"x.png","lat":1,"lng":2}]}';
    const map =
        '{"version":1,"siteId":"t","width":1,"height":1,"cellMeters":4,'
        '"origin":{"lat":1,"lng":2},"terrain":"AA==","labels":[]}';
    final bundles = await ContentRepository(
      _MapBundle({
        'assets/sites/index.json': '{"sites":["t"]}',
        'assets/sites/t/site.json': site,
        'assets/sites/t/items.json': items,
        'assets/sites/t/tilemap.json': map,
      }),
    ).loadAll();
    expect(bundles.single.site.id, 't');
    expect(bundles.single.items.single.id, 'i1');
    expect(bundles.single.map.width, 1);
  });
}
