import 'package:clock/clock.dart';
import 'package:fogcatcher/config/constants.dart';
import 'package:fogcatcher/game/game_phase.dart';
import 'package:fogcatcher/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gameControllerProvider wires repo, content and sources', () async {
    SharedPreferences.setMockInitialValues({'player.name': 'Ana'});
    final prefs = await SharedPreferences.getInstance();
    final fake = FakePositionSource();
    final notifier = FakeNotifier();
    final container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        contentProvider.overrideWithValue([testBundle()]),
        realPositionSourceProvider.overrideWithValue(fake),
        notifierProvider.overrideWithValue(notifier),
      ],
    );
    addTearDown(container.dispose);

    final state = withClock(
      Clock.fixed(eventEnd.subtract(const Duration(days: 4))),
      () => container.read(gameControllerProvider),
    );
    expect(state.siteId, 'demo_park');
    expect(state.playerName, 'Ana');
    expect(state.phase, GamePhase.playing);
    expect(container.read(positionSourceProvider).real, same(fake));

    await container.read(gameControllerProvider.notifier).startExploring();
    expect(fake.running, isTrue);
    expect(container.read(progressRepositoryProvider).exploring, isTrue);
  });
}
