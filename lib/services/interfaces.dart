// coverage:ignore-file (declarations only)
import 'dart:typed_data';

import '../models/item.dart';
import '../models/position_fix.dart';

abstract class PositionSource {
  Stream<PositionFix> get fixes; // errors when the source stopped itself
  bool get isRunning;
  Future<void> start();
  Future<void> stop();
}

abstract class ItemFoundNotifier {
  Future<void> init();
  Future<void> showItemFound(Item item); // posts the "Item found!" notification
  Stream<String> get taps; // item ids from tapped notifications
  String? takeLaunchItemId(); // id of a tap that cold-started the app, once
}

abstract class ScoreSharer {
  Future<void> sharePng(Uint8List png, {required String caption});
}

abstract class SystemSettings {
  Future<bool> requestLocationPermission(); // true if while-in-use granted
  Future<bool> hasPreciseLocation(); // false for Android's "Approximate"
  Future<bool> requestNotificationPermission();
  Future<void> openBatteryOptimizationSettings();
  Future<void> openAppSettings();
}
