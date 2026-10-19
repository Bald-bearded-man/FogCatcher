import 'dart:math';

import 'package:clock/clock.dart';
import 'package:fogcatcher/config/constants.dart';
import 'package:fogcatcher/game/debug_pin.dart';
import 'package:fogcatcher/main.dart';
import 'package:fogcatcher/map/sprite_sheets.dart';
import 'package:fogcatcher/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes.dart';

final playingNow = eventEnd.subtract(const Duration(days: 4));
final endedNow = eventEnd.add(const Duration(days: 1));

class AppHarness {
  AppHarness(this.prefs);
  final SharedPreferences prefs;
  final source = FakePositionSource();
  final notifier = FakeNotifier();
  final sharer = FakeSharer();
  final settings = FakeSettings();

  ProviderContainer container(WidgetTester t) =>
      ProviderScope.containerOf(t.element(find.byType(FogCatcherApp)));
}

/// Runs [body] with the clock fixed at [now].
void testApp(
  String description,
  Future<void> Function(WidgetTester t) body, {
  DateTime? now,
}) => testWidgets(
  description,
  (t) => withClock(Clock.fixed(now ?? playingNow), () => body(t)),
);

/// Pumps the whole app with fakes; [sheets] null keeps the map fallback.
Future<AppHarness> pumpApp(
  WidgetTester t, {
  Map<String, Object> prefs = const {},
  bool location = true,
  bool precise = true,
  SpriteSheets? sheets,
  String debugPinSha256 = '',
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final h = AppHarness(await SharedPreferences.getInstance());
  h.settings
    ..location = location
    ..precise = precise;
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(h.prefs),
        contentProvider.overrideWithValue([testBundle()]),
        realPositionSourceProvider.overrideWithValue(h.source),
        notifierProvider.overrideWithValue(h.notifier),
        sharerProvider.overrideWithValue(h.sharer),
        systemSettingsProvider.overrideWithValue(h.settings),
        // Seed 2 picks the knight on first opening.
        randomProvider.overrideWithValue(Random(2)),
        debugPinGateProvider.overrideWithValue(DebugPinGate(debugPinSha256)),
        spriteSheetsProvider.overrideWith(
          (_) async => sheets ?? (throw StateError('no tile assets')),
        ),
      ],
      child: const FogCatcherApp(),
    ),
  );
  await t.pump();
  return h;
}

/// Pumps [count] frames [step] apart so routes and sheets finish animating.
Future<void> settle(
  WidgetTester t, {
  int count = 10,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < count; i++) {
    await t.pump(step);
  }
}

Future<void> openMenuItem(WidgetTester t, String label) async {
  await t.tap(find.byIcon(Icons.menu));
  await settle(t);
  await t.tap(find.text(label).last);
  await settle(t);
}
