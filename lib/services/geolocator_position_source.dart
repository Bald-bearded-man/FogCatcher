// coverage:ignore-file (plugin glue, needs a device)
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/geo_point.dart';
import '../models/position_fix.dart';
import 'interfaces.dart';

class GeolocatorPositionSource implements PositionSource {
  GeolocatorPositionSource({
    required this.notificationTitle,
    required this.notificationText,
    required this.channelName,
  });
  final String notificationTitle;
  final String notificationText;
  final String channelName;

  final _controller = StreamController<PositionFix>.broadcast();
  StreamSubscription<Position>? _sub;

  @override
  Stream<PositionFix> get fixes => _controller.stream;
  @override
  bool get isRunning => _sub != null;

  @override
  Future<void> start() async {
    if (_sub != null) return;
    _sub =
        Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
            intervalDuration: const Duration(seconds: 5),
            foregroundNotificationConfig: ForegroundNotificationConfig(
              notificationTitle: notificationTitle,
              notificationText: notificationText,
              notificationIcon: const AndroidResource(
                name: 'ic_stat_notify',
                defType: 'drawable',
              ),
              enableWakeLock: true,
              setOngoing: true,
              notificationChannelName: channelName,
            ),
          ),
        ).listen(
          (p) => _controller.add(
            PositionFix(
              point: GeoPoint(p.latitude, p.longitude),
              accuracyMeters: p.accuracy,
              time: p.timestamp.toUtc(),
            ),
          ),
          // The plugin stream is dead after an error; stop first so isRunning is false.
          onError: (Object e) {
            debugPrint('Location stream error: $e');
            final sub = _sub;
            _sub = null;
            unawaited(sub?.cancel());
            _controller.addError(e);
          },
          onDone: () {
            _sub = null;
            _controller.addError(StateError('Location stream ended'));
          },
        );
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
