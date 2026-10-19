import 'package:fogcatcher/config/constants.dart';
import 'package:fogcatcher/game/game_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'playing before the end',
    () => expect(
      gamePhase(eventEnd.subtract(const Duration(seconds: 1))),
      GamePhase.playing,
    ),
  );
  test(
    'playing at exactly the end second',
    () => expect(gamePhase(eventEnd), GamePhase.playing),
  );
  test(
    'ended after the end',
    () => expect(
      gamePhase(eventEnd.add(const Duration(seconds: 1))),
      GamePhase.ended,
    ),
  );
  test('override wins', () {
    expect(
      gamePhase(
        eventEnd.add(const Duration(days: 365)),
        override: PhaseOverride.playing,
      ),
      GamePhase.playing,
    );
    expect(
      gamePhase(
        eventEnd.subtract(const Duration(days: 365)),
        override: PhaseOverride.ended,
      ),
      GamePhase.ended,
    );
  });
}
