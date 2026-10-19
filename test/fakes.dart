import 'dart:async';
import 'dart:typed_data';

import 'package:fogcatcher/game/geo.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/item.dart';
import 'package:fogcatcher/models/position_fix.dart';
import 'package:fogcatcher/models/site.dart';
import 'package:fogcatcher/models/terrain.dart';
import 'package:fogcatcher/models/tile_map.dart';
import 'package:fogcatcher/services/content_repository.dart';
import 'package:fogcatcher/services/interfaces.dart';

class FakeNotifier implements ItemFoundNotifier {
  final shown = <String>[];
  final _taps = StreamController<String>.broadcast();
  String? launchItemId;
  @override
  Future<void> init() async {}
  @override
  Future<void> showItemFound(Item item) async => shown.add(item.id);
  @override
  Stream<String> get taps => _taps.stream;
  @override
  String? takeLaunchItemId() {
    final id = launchItemId;
    launchItemId = null;
    return id;
  }

  void tap(String id) => _taps.add(id);
}

class FakePositionSource implements PositionSource {
  final _c = StreamController<PositionFix>.broadcast();
  bool running = false;
  bool failOnStart = false; // e.g. location off and the enable prompt dismissed
  int starts = 0, stops = 0;
  @override
  Stream<PositionFix> get fixes => _c.stream;
  @override
  bool get isRunning => running;
  @override
  Future<void> start() async {
    running = !failOnStart;
    starts++;
  }

  @override
  Future<void> stop() async {
    running = false;
    stops++;
  }

  void push(PositionFix f) => _c.add(f);

  /// Stops itself and reports it, like geolocator when location is switched off.
  void lose() {
    running = false;
    _c.addError(StateError('location off'));
  }
}

class FakeSharer implements ScoreSharer {
  Object? error;
  final calls = <(Uint8List, String)>[];
  @override
  Future<void> sharePng(Uint8List png, {required String caption}) async =>
      error != null ? throw error! : calls.add((png, caption));
}

class FakeSettings implements SystemSettings {
  FakeSettings({
    this.location = true,
    this.notifications = true,
    this.precise = true,
  });
  bool location, notifications, precise;
  final calls = <String>[];
  @override
  Future<bool> requestLocationPermission() async {
    calls.add('location');
    return location;
  }

  @override
  Future<bool> hasPreciseLocation() async => precise;

  @override
  Future<bool> requestNotificationPermission() async {
    calls.add('notifications');
    return notifications;
  }

  @override
  Future<void> openBatteryOptimizationSettings() async => calls.add('battery');
  @override
  Future<void> openAppSettings() async => calls.add('appSettings');
}

const demoOrigin = GeoPoint(43.654, 6.986);
const parisPoint = GeoPoint(48.8566, 2.3522);

/// 100×100 cells of 4 m (400 m square) with the site centred in it.
LocalProjection testProjection(GeoPoint origin) =>
    LocalProjection(origin: origin, refLat: origin.lat - 0.002);

GeoPoint testCenter(GeoPoint origin) =>
    testProjection(origin).fromMeters(200, 200);

/// Item `ids[0]` at the centre, `ids[1]` [spacing] metres east of it.
GeoPoint testItemPoint(GeoPoint origin, int index, {double spacing = 100}) =>
    testProjection(origin).fromMeters(200 + index * spacing, 200);

/// Two-item test site at [demoOrigin] with a 100×100 grass TileMap.
SiteBundle testBundle({
  String id = 'demo_park',
  GeoPoint origin = demoOrigin,
  List<String> ids = const ['a', 'b'],
  double spacing = 100,
  double radius = 20,
}) {
  final proj = testProjection(origin);
  final se = proj.fromMeters(400, 400);
  return SiteBundle(
    Site(
      id: id,
      name: 'Site $id',
      center: testCenter(origin),
      radiusMeters: 150,
      bounds: GeoBounds(
        south: se.lat,
        west: origin.lng,
        north: origin.lat,
        east: se.lng,
      ),
    ),
    [
      for (var i = 0; i < ids.length; i++)
        Item(
          id: ids[i],
          title: 'Item ${ids[i]}',
          text: 'Text ${ids[i]}',
          image: 'assets/sites/$id/images/${ids[i]}.png',
          position: testItemPoint(origin, i, spacing: spacing),
          radiusMeters: radius,
        ),
    ],
    TileMap(
      siteId: id,
      width: 100,
      height: 100,
      cellMeters: 4,
      origin: origin,
      cells: Uint8List(100 * 100)..fillRange(0, 100 * 100, Terrain.grass.index),
    ),
  );
}

PositionFix fixAt(GeoPoint p, {double accuracy = 5, DateTime? time}) =>
    PositionFix(
      point: p,
      accuracyMeters: accuracy,
      time: time ?? DateTime.utc(2030, 6, 1, 12),
    );
