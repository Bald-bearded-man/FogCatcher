import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:crypto/crypto.dart';

const debugPinMaxAttempts = 5;
const debugPinLockout = Duration(minutes: 10);

enum PinResult { ok, wrong, locked }

/// Checks the debug PIN against a SHA-256 set at build time, so the PIN never ships.
class DebugPinGate {
  DebugPinGate(String sha256Hex) : _hash = sha256Hex.trim().toLowerCase();
  final String _hash;
  int _wrong = 0;
  DateTime? _lockedUntil;

  /// False when the build has no hash: debug is then unreachable.
  bool get enabled => _hash.isNotEmpty;

  bool get locked {
    final until = _lockedUntil;
    return until != null && clock.now().isBefore(until);
  }

  PinResult check(String pin) {
    if (locked) return PinResult.locked;
    if (enabled && sha256.convert(utf8.encode(pin)).toString() == _hash) {
      _wrong = 0;
      return PinResult.ok;
    }
    if (++_wrong < debugPinMaxAttempts) return PinResult.wrong;
    _wrong = 0;
    _lockedUntil = clock.now().add(debugPinLockout);
    return PinResult.locked;
  }
}
