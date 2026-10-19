import 'package:fogcatcher/screens/map_screen.dart';
import 'package:fogcatcher/screens/onboarding_screen.dart';
import 'package:fogcatcher/screens/score_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

void main() {
  testApp('no stored name while playing shows onboarding', (t) async {
    await pumpApp(t);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(MapScreen), findsNothing);
  });

  testApp('stored name while playing shows the map', (t) async {
    await pumpApp(t, prefs: {'player.name': 'Ana'});
    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testApp('router shows only the score screen when ended', (t) async {
    final h = await pumpApp(t, prefs: {'player.name': 'Ana'});
    final score = t.widget<ScoreScreen>(find.byType(ScoreScreen));
    expect(score.gameOver, isTrue);
    expect(find.byType(MapScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(h.source.starts, 0);
  }, now: endedNow);

  testApp('ended with no name shows the anonymous card at 0 / 2', (t) async {
    await pumpApp(t);
    expect(find.byType(ScoreScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Mystery adventurer'), findsOneWidget);
    expect(find.textContaining('0 / 2'), findsOneWidget);
  }, now: endedNow);
}
