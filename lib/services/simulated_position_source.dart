import 'dart:async';

import 'package:clock/clock.dart';

import '../models/geo_point.dart';
import '../models/position_fix.dart';
import 'interfaces.dart';

/// Debug teleport: fixes are pushed by hand via [emit].
class SimulatedPositionSource implements PositionSource {
  final _controller = StreamController<PositionFix>.broadcast();
  bool _running = false;

  @override
  Stream<PositionFix> get fixes => _controller.stream;
  @override
  bool get isRunning => _running;
  @override
  Future<void> start() async => _running = true;
  @override
  Future<void> stop() async => _running = false;

  void emit(GeoPoint p) {
    if (!_running) return;
    _controller.add(
      PositionFix(
        point: p,
        accuracyMeters: 5,
        time: clock.now().toUtc(),
        simulated: true,
      ),
    );
  }
}

/// Routes to the simulated source while debug teleport is on, else to the real one.
class SwitchablePositionSource implements PositionSource {
  SwitchablePositionSource(this.real, this.simulated) {
    real.fixes.listen(
      (f) {
        if (!_useSimulated) _out.add(f);
      },
      onError: (Object e, StackTrace st) {
        if (!_useSimulated) _out.addError(e, st);
      },
    );
    simulated.fixes.listen((f) {
      if (_useSimulated) _out.add(f);
    });
  }

  final PositionSource real;
  final PositionSource simulated;
  bool _useSimulated = false;
  final _out = StreamController<PositionFix>.broadcast();

  bool get useSimulated => _useSimulated;

  /// Turning it on starts the simulated source, off stops it.
  set useSimulated(bool v) {
    if (v == _useSimulated) return;
    _useSimulated = v;
    unawaited(v ? simulated.start() : simulated.stop());
  }

  @override
  Stream<PositionFix> get fixes => _out.stream;
  @override
  bool get isRunning => _useSimulated ? simulated.isRunning : real.isRunning;
  @override
  Future<void> start() => real.start();
  @override
  Future<void> stop() async {
    await real.stop();
    await simulated.stop();
  }
}
