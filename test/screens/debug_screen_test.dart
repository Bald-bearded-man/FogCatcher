import 'package:fogcatcher/providers/providers.dart';
import 'package:fogcatcher/screens/debug_screen.dart';
import 'package:fogcatcher/screens/map_screen.dart';
import 'package:fogcatcher/screens/score_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

const named = {'player.name': 'Ana'};
// sha256 of '246810'.
const pinHash =
    '7c2523c985881fb2c2b4cfbe917eb12c4c4b61e898ad4e7160cfca487ca3c4f3';

Future<void> tapVersion(WidgetTester t, int n) async {
  for (var i = 0; i < n; i++) {
    await t.tap(find.text('Version dev'));
    await t.pump();
  }
  await settle(t);
}

Future<void> enterPin(WidgetTester t, String pin) async {
  await t.enterText(find.byType(TextField), pin);
  await t.tap(find.text('OK'));
  await settle(t);
}

void main() {
  testApp('About shows the developer under the version', (t) async {
    await pumpApp(t, prefs: {'player.name': 'Ana'});
    await openMenuItem(t, 'About');
    final dev = find.text('Developed by BaldMan');
    expect(dev, findsOneWidget);
    expect(
      t.getTopLeft(dev).dy,
      greaterThan(t.getTopLeft(find.text('Version dev')).dy),
    );
  });

  testApp('seven taps then the right PIN enable debug mode', (t) async {
    final h = await pumpApp(t, prefs: named, debugPinSha256: pinHash);
    await openMenuItem(t, 'About');
    await tapVersion(t, 6);
    expect(find.text('Enter PIN'), findsNothing);
    await tapVersion(t, 1);
    expect(find.text('Enter PIN'), findsOneWidget);
    await enterPin(t, '246810');
    expect(find.text('Enter PIN'), findsNothing);
    expect(find.text('Debug mode enabled'), findsOneWidget);
    expect(find.text('Licenses'), findsOneWidget);
    expect(h.prefs.getBool('debug.enabled'), isTrue);
  });

  testApp('a wrong PIN shows the error and keeps debug off', (t) async {
    final h = await pumpApp(t, prefs: named, debugPinSha256: pinHash);
    await openMenuItem(t, 'About');
    await tapVersion(t, 7);
    await enterPin(t, '123456');
    expect(find.text('Wrong PIN'), findsOneWidget);
    expect(find.text('Enter PIN'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await settle(t);
    expect(h.prefs.getBool('debug.enabled'), isNull);
  });

  testApp('without a PIN hash in the build, seven taps do nothing', (t) async {
    final h = await pumpApp(t, prefs: named);
    await openMenuItem(t, 'About');
    await tapVersion(t, 14);
    expect(find.text('Enter PIN'), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(h.prefs.getBool('debug.enabled'), isNull);
  });

  testApp('five wrong PINs lock the dialog, even for the right PIN', (t) async {
    final h = await pumpApp(t, prefs: named, debugPinSha256: pinHash);
    await openMenuItem(t, 'About');
    await tapVersion(t, 7);
    for (var i = 0; i < 4; i++) {
      await enterPin(t, '000000');
      expect(find.text('Wrong PIN'), findsOneWidget);
    }
    await enterPin(t, '000000');
    const locked = 'Too many tries. Try again in 10 minutes.';
    expect(find.text(locked), findsOneWidget);
    expect(t.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await t.tap(find.text('Cancel'));
    await settle(t);
    await tapVersion(t, 7);
    expect(find.text(locked), findsOneWidget);
    expect(h.prefs.getBool('debug.enabled'), isNull);
  });

  testApp('force find, reset, then forcing the end shows the score', (t) async {
    final h = await pumpApp(
      t,
      prefs: {'player.name': 'Ana', 'debug.enabled': true},
    );
    await openMenuItem(t, 'Debug mode');
    expect(find.byType(DebugScreen), findsOneWidget);

    final rowB = find.widgetWithText(ListTile, 'Item b');
    await t.tap(find.descendant(of: rowB, matching: find.text('Find')));
    await t.pump();
    expect(
      h.container(t).read(gameControllerProvider).found.keys,
      contains('b'),
    );
    expect(h.prefs.getString('progress.demo_park.found'), contains('"b"'));

    await t.ensureVisible(find.text('Reset progress'));
    await t.tap(find.text('Reset progress'));
    await settle(t);
    expect(
      find.text('Erase all items and map progress for this site?'),
      findsOneWidget,
    );
    await t.tap(find.text('Cancel'));
    await settle(t);
    expect(h.prefs.getString('progress.demo_park.found'), contains('"b"'));
    await t.tap(find.text('Reset progress'));
    await settle(t);
    await t.tap(find.text('OK'));
    await settle(t);
    expect(h.container(t).read(gameControllerProvider).found.keys, isEmpty);
    expect(h.prefs.getString('progress.demo_park.found'), isNull);

    await t.tap(find.text('Ended'));
    await settle(t);
    expect(find.byType(DebugScreen), findsNothing);
    expect(find.byType(MapScreen), findsNothing);
    expect(t.widget<ScoreScreen>(find.byType(ScoreScreen)).gameOver, isTrue);
  });
}
