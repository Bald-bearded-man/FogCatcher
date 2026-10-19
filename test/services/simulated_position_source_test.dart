import 'package:clock/clock.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/position_fix.dart';
import 'package:fogcatcher/services/interfaces.dart';
import 'package:fogcatcher/services/simulated_position_source.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSource implements PositionSource {
  _FakeSource(this.stream);
  final Stream<PositionFix> stream;
  bool running = false;
  @override
  Stream<PositionFix> get fixes => stream;
  @override
  bool get isRunning => running;
  @override
  Future<void> start() async => running = true;
  @override
  Future<void> stop() async => running = false;
}

void main() {
  test('emits simulated fixes only while running', () async {
    final s = SimulatedPositionSource();
    final got = <GeoPoint>[];
    s.fixes.listen((f) {
      got.add(f.point);
      expect(f.simulated, isTrue);
      expect(f.accuracyMeters, 5);
    });
    s.emit(const GeoPoint(1, 1)); // not running: dropped
    await s.start();
    await withClock(
      Clock.fixed(DateTime.utc(2030, 6, 1)),
      () async => s.emit(const GeoPoint(2, 2)),
    );
    await s.stop();
    s.emit(const GeoPoint(3, 3));
    await Future<void>.delayed(Duration.zero);
    expect(got, [const GeoPoint(2, 2)]);
  });

  test(
    'switchable source starts/stops the simulated side with the toggle',
    () async {
      final sim = SimulatedPositionSource();
      final realSim = SimulatedPositionSource(); // stands in for the GPS stream
      final sw = SwitchablePositionSource(_FakeSource(realSim.fixes), sim);
      final got = <GeoPoint>[];
      sw.fixes.listen((f) => got.add(f.point));
      Future<void> tick() => Future<void>.delayed(Duration.zero);

      await sw.start();
      await realSim.start();
      realSim.emit(const GeoPoint(1, 1));
      sim.emit(const GeoPoint(9, 9)); // sim not running: dropped
      await tick();
      expect(got, [const GeoPoint(1, 1)]);

      sw.useSimulated = true; // starts the simulated source
      await tick();
      expect(sw.isRunning, isTrue);
      realSim.emit(const GeoPoint(2, 2)); // real ignored while simulated
      sim.emit(const GeoPoint(3, 3));
      await tick();
      expect(got, [const GeoPoint(1, 1), const GeoPoint(3, 3)]);

      sw.useSimulated = false; // stops it again
      await tick();
      sim.emit(const GeoPoint(4, 4));
      realSim.emit(const GeoPoint(5, 5));
      await tick();
      expect(got.last, const GeoPoint(5, 5));
      expect(got, hasLength(3));

      sw.useSimulated = true;
      await tick();
      await sw.stop();
      sim.emit(const GeoPoint(6, 6));
      await tick();
      expect(got, hasLength(3));
      expect(sw.isRunning, isFalse);
    },
  );
}
