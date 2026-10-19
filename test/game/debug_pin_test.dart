import 'package:clock/clock.dart';
import 'package:fogcatcher/game/debug_pin.dart';
import 'package:flutter_test/flutter_test.dart';

// sha256 of '246810'.
const _hash =
    '7c2523c985881fb2c2b4cfbe917eb12c4c4b61e898ad4e7160cfca487ca3c4f3';

void main() {
  final t0 = DateTime.utc(2030, 6, 1, 12);
  PinResult at(DebugPinGate g, Duration after, String pin) =>
      withClock(Clock.fixed(t0.add(after)), () => g.check(pin));

  test('empty hash disables the gate and accepts nothing', () {
    final g = DebugPinGate('  ');
    expect(g.enabled, isFalse);
    expect(g.check(''), PinResult.wrong);
  });

  test('right PIN passes, hash case and spaces do not matter', () {
    final g = DebugPinGate(' ${_hash.toUpperCase()} ');
    expect(g.enabled, isTrue);
    expect(g.check('246810'), PinResult.ok);
    expect(g.check('24681'), PinResult.wrong);
  });

  test('five wrong tries lock for 10 minutes, then the count restarts', () {
    final g = DebugPinGate(_hash);
    for (var i = 0; i < 4; i++) {
      expect(at(g, Duration.zero, '1'), PinResult.wrong);
    }
    expect(at(g, Duration.zero, '1'), PinResult.locked);
    expect(at(g, const Duration(minutes: 9), '246810'), PinResult.locked);
    expect(withClock(Clock.fixed(t0), () => g.locked), isTrue);
    expect(at(g, const Duration(minutes: 10), '1'), PinResult.wrong);
    expect(at(g, const Duration(minutes: 10), '246810'), PinResult.ok);
  });

  test('a right PIN resets the wrong count', () {
    final g = DebugPinGate(_hash);
    for (var i = 0; i < 4; i++) {
      g.check('1');
    }
    expect(g.check('246810'), PinResult.ok);
    for (var i = 0; i < 4; i++) {
      expect(g.check('1'), PinResult.wrong);
    }
  });
}
