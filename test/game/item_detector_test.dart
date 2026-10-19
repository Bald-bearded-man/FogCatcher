import 'package:fogcatcher/game/item_detector.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/item.dart';
import 'package:flutter_test/flutter_test.dart';

Item item(String id, double lat, double lng, {double r = 20}) => Item(
  id: id,
  title: id,
  text: '',
  image: '',
  position: GeoPoint(lat, lng),
  radiusMeters: r,
);

void main() {
  final a = item('a', 43.6500, 6.9900);
  final b = item('b', 43.6501, 6.9900, r: 30); // ~11 m north of a
  final far = item('far', 43.6600, 6.9900);
  test(
    'finds an item within its radius',
    () => expect(
      detectItems(const GeoPoint(43.65015, 6.9900), [
        a,
        far,
      ], {}).map((i) => i.id),
      ['a'],
    ),
  );
  test(
    'ignores items already found',
    () => expect(
      detectItems(const GeoPoint(43.6500, 6.9900), [a], {'a'}),
      isEmpty,
    ),
  );
  test(
    'detector finds every item in range of one fix',
    () => expect(
      detectItems(const GeoPoint(43.65005, 6.9900), [
        a,
        b,
        far,
      ], {}).map((i) => i.id),
      ['a', 'b'],
    ),
  );
  test('edge: 19 m in, 21 m out', () {
    expect(
      detectItems(const GeoPoint(43.650171, 6.9900), [a], {}),
      hasLength(1),
    ); // ~19 m
    expect(
      detectItems(const GeoPoint(43.650189, 6.9900), [a], {}),
      isEmpty,
    ); // ~21 m
  });
}
