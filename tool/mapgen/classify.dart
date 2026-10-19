import 'package:fogcatcher/models/terrain.dart';

const _voidLanduse = {'farmland', 'railway', 'construction', 'military'};
const _pathHighways = {
  'footway',
  'path',
  'pedestrian',
  'steps',
  'cycleway',
  'track',
  'service',
};

/// Places players must not or cannot go.
bool isVoid(Map<String, String> tags) =>
    tags['leisure'] == 'golf_course' ||
    tags.containsKey('golf') ||
    tags['sport'] == 'archery' ||
    tags['sport'] == 'golf' ||
    (_restricted(tags['access']) && tags['leisure'] != 'swimming_pool') ||
    _voidLanduse.contains(tags['landuse']);

// Resort pools are tagged access=private (guests only); players are guests, so they stay water.
bool _restricted(String? access) => access == 'private' || access == 'no';

Terrain? classify(Map<String, String> tags) {
  final highway = tags['highway'], leisure = tags['leisure'];
  final natural = tags['natural'];
  if (natural == 'water' ||
      leisure == 'swimming_pool' ||
      tags.containsKey('water')) {
    return Terrain.water;
  }
  if (tags.containsKey('building')) return Terrain.building;
  if (highway != null) {
    return _pathHighways.contains(highway) ? Terrain.path : Terrain.road;
  }
  if (tags['amenity'] == 'parking') return Terrain.parking;
  if (const {'pitch', 'sports_centre', 'playground'}.contains(leisure)) {
    return Terrain.court;
  }
  if (natural == 'sand' || natural == 'beach') return Terrain.sand;
  if (const {'wood', 'tree_row', 'scrub'}.contains(natural) ||
      tags['landuse'] == 'forest') {
    return Terrain.wood;
  }
  return null;
}

const _golfAreas = {
  'tee',
  'green',
  'bunker',
  'fairway',
  'rough',
  'driving_range',
};

/// Stroke width that voids around golf features: a fairway corridor along holes,
/// a 10 m buffer around tees, greens and the like (the course outline is incomplete).
double? golfVoidStroke(Map<String, String> tags) => switch (tags['golf']) {
  'hole' => 60,
  final String g when _golfAreas.contains(g) => 20,
  _ => null,
};

/// Linear features are stroked, not filled.
double? strokeWidth(Terrain t) => switch (t) {
  Terrain.path => 3,
  Terrain.road => 7,
  _ => null,
};
