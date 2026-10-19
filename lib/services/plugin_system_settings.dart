import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

import 'interfaces.dart';

// coverage:ignore-file
class PluginSystemSettings implements SystemSettings {
  @override
  Future<bool> requestLocationPermission() async {
    final p = await Geolocator.requestPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  @override
  Future<bool> hasPreciseLocation() async =>
      await Geolocator.getLocationAccuracy() == LocationAccuracyStatus.precise;

  @override
  Future<bool> requestNotificationPermission() async =>
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission() ??
      false;

  @override
  Future<void> openBatteryOptimizationSettings() =>
      AppSettings.openAppSettings(type: AppSettingsType.batteryOptimization);

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();
}
