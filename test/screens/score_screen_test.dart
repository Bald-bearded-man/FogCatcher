import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fogcatcher/config/constants.dart';
import 'package:fogcatcher/l10n/generated/app_localizations.dart';
import 'package:fogcatcher/screens/score_screen.dart';
import 'package:fogcatcher/widgets/pixel_kit.dart';
import 'package:fogcatcher/widgets/score_card.dart';

import '../fakes.dart';

Widget wrap(Widget w) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: w,
);

ScoreCardData data([String name = 'Zoé']) => ScoreCardData(
  playerName: name,
  found: 5,
  total: 12,
  thumbnails: const ['assets/missing/a.png'],
);

void main() {
  testWidgets('gameOver shows the end text, one share button, no back', (
    t,
  ) async {
    await t.pumpWidget(
      wrap(ScoreScreen(data: data(), sharer: FakeSharer(), gameOver: true)),
    );
    expect(find.text('The adventure is over!'), findsOneWidget);
    expect(find.byType(PixelButton), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(BackButton), findsNothing);
    final pop = t.widget<PopScope>(find.byType(PopScope));
    expect(pop.canPop, isFalse);
  });

  testWidgets('share renders a PNG and calls the sharer', (t) async {
    final sharer = FakeSharer();
    await t.pumpWidget(wrap(ScoreScreen(data: data(), sharer: sharer)));
    await t.runAsync(() async {
      await t.tap(find.text('Share my score'));
      for (var i = 0; i < 50 && sharer.calls.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    expect(sharer.calls, hasLength(1));
    final (png, caption) = sharer.calls.single;
    expect(png.sublist(0, 4), [137, 80, 78, 71]);
    expect(caption, 'I found 5 of 12 items in $appTitle 🗺️');
  });

  testWidgets('empty player name shows the anonymous label', (t) async {
    await t.pumpWidget(wrap(ScoreScreen(data: data(''), sharer: FakeSharer())));
    expect(find.text('Mystery adventurer'), findsOneWidget);
  });

  testWidgets('double tap shares once', (t) async {
    final sharer = FakeSharer();
    await t.pumpWidget(wrap(ScoreScreen(data: data(), sharer: sharer)));
    await t.runAsync(() async {
      await t.tap(find.text('Share my score'));
      await t.pump();
      await t.tap(find.byType(PixelButton), warnIfMissed: false);
      for (var i = 0; i < 50 && sharer.calls.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    expect(sharer.calls, hasLength(1));
  });

  testWidgets('sharer failure shows a snackbar and re-enables the button', (
    t,
  ) async {
    final sharer = FakeSharer()..error = StateError('boom');
    await t.pumpWidget(wrap(ScoreScreen(data: data(), sharer: sharer)));
    await t.runAsync(() async {
      await t.tap(find.text('Share my score'));
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await t.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(
      t.widget<PixelButton>(find.byType(PixelButton)).onPressed,
      isNotNull,
    );
    expect(t.widget<PixelButton>(find.byType(PixelButton)).busy, isFalse);
  });
}
