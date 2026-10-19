import 'geo_point.dart';

class Item {
  const Item({
    required this.id,
    required this.title,
    required this.text,
    required this.image,
    required this.position,
    this.radiusMeters = 20,
  });
  final String id;
  final String title;
  final String text;
  final String image; // asset path, e.g. assets/items/demo_park-fountain.webp
  final GeoPoint position;
  final double radiusMeters;
  factory Item.fromJson(Map<String, dynamic> j) => Item(
    id: j['id'] as String,
    title: j['title'] as String,
    text: j['text'] as String,
    image: j['image'] as String,
    position: GeoPoint(
      (j['lat'] as num).toDouble(),
      (j['lng'] as num).toDouble(),
    ),
    radiusMeters: (j['radiusMeters'] as num?)?.toDouble() ?? 20,
  );
}
