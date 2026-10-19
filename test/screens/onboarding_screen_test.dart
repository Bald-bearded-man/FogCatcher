import 'package:fogcatcher/models/avatar.dart';
import 'package:fogcatcher/screens/map_screen.dart';
import 'package:fogcatcher/screens/onboarding_screen.dart';
import 'package:fogcatcher/widgets/app_logo.dart';
import 'package:fogcatcher/widgets/pixel_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

PixelButton button(WidgetTester t, String label) =>
    t.widget<PixelButton>(find.widgetWithText(PixelButton, label));

Future<void> tapText(WidgetTester t, String text) async {
  await t.tap(find.text(text));
  await t.pump();
  await t.pump();
}

Future<void> enterName(WidgetTester t, String name) async {
  await t.enterText(find.byType(TextField), name);
  await t.pump();
  await tapText(t, 'Continue');
}

/// Name step, then the avatar step with the default pick.
Future<void> toLocation(WidgetTester t, String name) async {
  await enterName(t, name);
  await tapText(t, 'Continue');
}

void main() {
  testApp('name step shows the large logo, later steps the compact', (t) async {
    await pumpApp(t);
    expect(t.widget<AppLogo>(find.byType(AppLogo)).size, AppLogoSize.large);
    await enterName(t, 'Ana');
    expect(
      t.widget<AppLogo>(find.byType(AppLogo).last).size,
      AppLogoSize.compact,
    );
  });

  testApp('Continue needs a name and persists it', (t) async {
    final h = await pumpApp(t);
    expect(button(t, 'Continue').onPressed, isNull);
    await t.enterText(find.byType(TextField), '   ');
    await t.pump();
    expect(button(t, 'Continue').onPressed, isNull);
    await t.enterText(find.byType(TextField), 'Ana');
    await t.pump();
    expect(button(t, 'Continue').onPressed, isNotNull);
    await tapText(t, 'Continue');
    expect(h.prefs.getString('player.name'), 'Ana');
    expect(find.text('Choose avatar'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testApp('avatar step follows the name and saves the pick', (t) async {
    final h = await pumpApp(t);
    // Random from the harness seed, saved before the step shows.
    expect(h.prefs.getString('player.avatar'), 'knight');
    await enterName(t, 'Ana');
    for (final a in Avatar.values) {
      expect(find.byKey(ValueKey('avatar-${a.name}')), findsOneWidget);
    }
    await t.tap(find.byKey(const ValueKey('avatar-ninja')));
    await t.pump();
    expect(h.prefs.getString('player.avatar'), 'ninja');
    await tapText(t, 'Continue');
    expect(find.text('The map needs your location'), findsOneWidget);
  });

  testApp('denied location shows the settings button and blocks', (t) async {
    final h = await pumpApp(t, location: false);
    await toLocation(t, 'Ana');
    await tapText(t, 'Allow location');
    expect(
      find.text(
        "Without your location you can't explore. Open settings to allow it.",
      ),
      findsOneWidget,
    );
    await tapText(t, 'Open settings');
    expect(h.settings.calls, ['location', 'appSettings']);
    expect(find.text('The map needs your location'), findsOneWidget);
    expect(find.text('Get notified of finds'), findsNothing);
    expect(find.text('Skip'), findsNothing);
  });

  testApp('approximate location is explained, then onboarding goes on', (
    t,
  ) async {
    final h = await pumpApp(t);
    h.settings.precise = false;
    await toLocation(t, 'Ana');
    await tapText(t, 'Allow location');
    await settle(t);
    expect(find.text('Precise location needed'), findsOneWidget);
    await t.tap(find.text('Open settings'));
    await settle(t);
    expect(h.settings.calls, ['location', 'appSettings']);
    expect(find.text('Get notified of finds'), findsOneWidget);
  });

  testApp('granted location walks notifications, battery, then the map', (
    t,
  ) async {
    final h = await pumpApp(t);
    await toLocation(t, 'Ana');
    await tapText(t, 'Allow location');
    expect(find.text('Get notified of finds'), findsOneWidget);
    await tapText(t, 'Skip');
    expect(find.text('Keep exploring in the background'), findsOneWidget);
    await tapText(t, 'Open battery settings');
    expect(h.settings.calls, ['location', 'battery']);
    expect(find.byType(MapScreen), findsNothing);
    await tapText(t, "Let's go!");
    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(h.source.starts, 0);
  });
}
