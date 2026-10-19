import 'dart:convert';

import 'package:fogcatcher/config/theme.dart';
import 'package:fogcatcher/map/game_map_view.dart';
import 'package:fogcatcher/map/markers_painter.dart';
import 'package:fogcatcher/models/avatar.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/widgets/avatar_sprite.dart';
import 'package:fogcatcher/widgets/pixel_kit.dart';
import 'package:fogcatcher/screens/collection_screen.dart';
import 'package:fogcatcher/widgets/app_logo.dart';
import 'package:fogcatcher/widgets/reveal_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';
import '../map/test_sheets.dart';
import 'app_harness.dart';

const named = {'player.name': 'Ana'};

Future<void> pushFix(WidgetTester t, AppHarness h, GeoPoint p) async {
  await t.tap(find.text('Start exploring'));
  await t.pump();
  await t.pump();
  h.source.push(fixAt(p));
  await t.pump();
  await t.pump();
}

final _pin = paints
  ..rect(color: AppColors.ink)
  ..rect(color: AppColors.ink)
  ..rect(color: AppColors.primary);

void main() {
  testApp('Stop asks first: Cancel keeps exploring, Stop stops', (t) async {
    final h = await pumpApp(t, prefs: named);
    await t.tap(find.text('Start exploring'));
    await t.pump();
    await t.pump();
    expect(h.source.isRunning, isTrue);
    await t.tap(find.text('Stop exploring'));
    await settle(t);
    expect(find.text('Stop exploring?'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await settle(t);
    expect(h.source.isRunning, isTrue);
    expect(find.text('Stop exploring'), findsOneWidget);
    await t.tap(find.text('Stop exploring'));
    await settle(t);
    await t.tap(find.text('Stop'));
    await settle(t);
    expect(h.source.isRunning, isFalse);
    expect(find.text('Start exploring'), findsOneWidget);
  });

  testApp('waiting for GPS shows while exploring without a fix', (t) async {
    final h = await pumpApp(t, prefs: named);
    expect(find.text('Waiting for GPS…'), findsNothing);
    await t.tap(find.text('Start exploring'));
    await t.pump();
    await t.pump();
    expect(find.text('Waiting for GPS…'), findsOneWidget);
    h.source.push(fixAt(testCenter(demoOrigin)));
    await t.pump();
    await t.pump();
    expect(find.text('Waiting for GPS…'), findsNothing);
  });

  testApp('a fix outside the site shows the distance banner', (t) async {
    final h = await pumpApp(t, prefs: named);
    // About 1.1 km north of the centre.
    final c = testCenter(demoOrigin);
    await pushFix(t, h, GeoPoint(c.lat + 0.01, c.lng));
    expect(
      find.text(
        "You're 1.1 km away from Site demo_park. Head there to start exploring!",
      ),
      findsOneWidget,
    );
    expect(find.text('Waiting for GPS…'), findsNothing);
  });

  testApp('a nearby fix outside shows metres; inside shows no banner', (
    t,
  ) async {
    final h = await pumpApp(t, prefs: named);
    final c = testCenter(demoOrigin);
    await pushFix(t, h, GeoPoint(c.lat + 0.0035, c.lng)); // ~389 m
    expect(find.textContaining(' m away from Site'), findsOneWidget);
    h.source.push(fixAt(c));
    await t.pump();
    await t.pump();
    expect(find.textContaining('away from'), findsNothing);
  });

  testApp('an inaccurate fix explains the weak GPS', (t) async {
    final h = await pumpApp(t, prefs: named);
    await t.tap(find.text('Start exploring'));
    await t.pump();
    await t.pump();
    h.source.push(fixAt(testCenter(demoOrigin), accuracy: 1500));
    await t.pump();
    await t.pump();
    expect(
      find.text('GPS signal too weak (±1500 m). Move outdoors.'),
      findsOneWidget,
    );
    expect(find.text('Waiting for GPS…'), findsNothing);
  });

  testApp('location switched off flips the button and explains', (t) async {
    final h = await pumpApp(t, prefs: named);
    await t.tap(find.text('Start exploring'));
    await t.pump();
    await t.pump();
    expect(find.text('Stop exploring'), findsOneWidget);
    h.source.lose();
    await t.pump();
    await t.pump();
    expect(find.text('Start exploring'), findsOneWidget);
    expect(
      find.text(
        'Location stopped. Make sure Location is on in your phone settings, '
        'then tap Start exploring.',
      ),
      findsOneWidget,
    );
  });

  testApp('reopening after the app was killed explains the stop', (t) async {
    final h = await pumpApp(t, prefs: {...named, 'exploring': true});
    const text =
        'Exploration stopped while the app was closed. '
        'Tap Start exploring to continue.';
    expect(find.text(text), findsOneWidget);
    expect(h.source.starts, 0);
    await t.tap(find.text('Start exploring'));
    await t.pump();
    await t.pump();
    expect(find.text(text), findsNothing);
  });

  testApp('resume notices a source that stopped silently', (t) async {
    final h = await pumpApp(t, prefs: named);
    await t.tap(find.text('Start exploring'));
    await t.pump();
    await t.pump();
    h.source.running = false;
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(find.text('Start exploring'), findsOneWidget);
    expect(h.prefs.getBool('exploring'), isFalse);
  });

  testApp('approximate location asks for precise and does not start', (
    t,
  ) async {
    final h = await pumpApp(t, prefs: named, precise: false);
    await t.tap(find.text('Start exploring'));
    await settle(t);
    expect(find.text('Precise location needed'), findsOneWidget);
    expect(h.source.starts, 0);
    await t.tap(find.text('Open settings'));
    await settle(t);
    expect(h.settings.calls, ['location', 'appSettings']);
    expect(find.text('Precise location needed'), findsNothing);
  });

  testApp('map shows the site pin before any fix', (t) async {
    final sheets = (await t.runAsync(testSheets))!;
    await pumpApp(t, prefs: named, sheets: sheets);
    await t.pump();
    final markers = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is MarkersPainter,
    );
    expect(t.renderObject(markers), _pin);
  });

  testApp('HUD and Stop button clear the status and nav bars', (t) async {
    t.view.physicalSize = const Size(360 * 3, 800 * 3);
    t.view.devicePixelRatio = 3;
    t.view.padding = const FakeViewPadding(top: 24 * 3, bottom: 48 * 3);
    t.view.viewPadding = const FakeViewPadding(top: 24 * 3, bottom: 48 * 3);
    addTearDown(t.view.reset);
    await pumpApp(t, prefs: named);
    expect(t.getTopLeft(find.byType(AppLogo)).dy, greaterThanOrEqualTo(24));
    final button = find.byType(PixelButton);
    expect(t.getBottomLeft(button).dy, lessThanOrEqualTo(800 - 48));
  });

  testApp('map bottom button clears the gesture bar', (t) async {
    t.view.physicalSize = const Size(360 * 3, 800 * 3);
    t.view.devicePixelRatio = 3;
    t.view.padding = const FakeViewPadding(bottom: 90);
    t.view.viewPadding = const FakeViewPadding(bottom: 90);
    addTearDown(t.view.reset);
    await pumpApp(t, prefs: named);
    final bottom = t.getBottomLeft(find.byType(PixelButton)).dy;
    expect(bottom, lessThanOrEqualTo(800 - 30));
  });

  testApp('HUD: centred logo row above avatar, name, score and menu', (
    t,
  ) async {
    t.view.physicalSize = const Size(360 * 3, 800 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    const name = 'Abcdefghijklmnopqrstuvwx'; // 24 characters, the maximum
    await pumpApp(t, prefs: {'player.name': name, 'player.avatar': 'pirate'});
    expect(t.takeException(), isNull);
    final logo = t.getRect(find.byType(AppLogo));
    final avatar = find.byType(AvatarSprite);
    final menu = find.byTooltip('Menu');
    expect(t.widget<AvatarSprite>(avatar).avatar, Avatar.pirate);
    expect(t.getSize(avatar), const Size.square(24));
    expect(logo.center.dx, closeTo(180, 8));
    for (final f in [avatar, find.text(name), find.text('0 / 2'), menu]) {
      expect(t.getRect(f).top, greaterThanOrEqualTo(logo.bottom), reason: '$f');
    }
    expect(t.getCenter(avatar).dx, lessThan(t.getRect(find.text(name)).left));
    expect(
      t.getRect(find.text(name)).right,
      lessThanOrEqualTo(t.getRect(find.text('0 / 2')).left),
    );
    expect(t.getRect(menu).right, lessThanOrEqualTo(360));
    expect(t.getSize(menu).width, greaterThanOrEqualTo(48));
    expect(t.getSize(menu).height, greaterThanOrEqualTo(48));
  });

  testApp('HUD shows name and score; start swaps to Stop exploring', (t) async {
    final h = await pumpApp(t, prefs: named);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('0 / 2'), findsOneWidget);
    expect(find.byTooltip('Menu'), findsOneWidget);
    expect(h.source.starts, 0);
    await t.tap(find.text('Start exploring'));
    await t.pump();
    await t.pump();
    expect(h.source.starts, 1);
    // Notifications are asked again in case onboarding was cut short.
    expect(h.settings.calls, ['location', 'notifications']);
    expect(find.text('Stop exploring'), findsOneWidget);
    expect(find.text('Start exploring'), findsNothing);
  });

  testApp('a fix on item A in front plays the reveal then scores', (t) async {
    final h = await pumpApp(t, prefs: named);
    await t.tap(find.text('Start exploring'));
    await t.pump();
    h.source.push(fixAt(testItemPoint(demoOrigin, 0)));
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    expect(find.byType(RevealOverlay), findsOneWidget);
    expect(find.text('Item a'), findsOneWidget);
    expect(h.notifier.shown, isEmpty);
    await t.tap(find.byType(RevealOverlay));
    await t.pump();
    await t.pump();
    expect(find.byType(RevealOverlay), findsNothing);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(h.prefs.getStringList('progress.demo_park.unseen'), isEmpty);
  });

  testApp('menu opens the collection and shares the score', (t) async {
    final h = await pumpApp(t, prefs: named);
    await openMenuItem(t, 'My loot');
    expect(find.byType(CollectionScreen), findsOneWidget);
    t.state<NavigatorState>(find.byType(Navigator)).pop();
    await settle(t);
    expect(find.byType(CollectionScreen), findsNothing);
    await t.tap(find.byIcon(Icons.menu));
    await settle(t);
    await t.tap(find.text('Share my score'));
    // Rendering mixes real I/O with fake-async frames: alternate both.
    for (var i = 0; i < 50 && h.sharer.calls.isEmpty; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(h.sharer.calls, hasLength(1));
    expect(h.sharer.calls.single.$2, contains('found 0 of 2 items'));
  });

  testApp('resuming with an unseen item plays its reveal', (t) async {
    addTearDown(
      () => t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
    );
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await pumpApp(
      t,
      prefs: {
        ...named,
        'progress.demo_park.found': jsonEncode({
          'a': playingNow.toIso8601String(),
        }),
        'progress.demo_park.unseen': ['a'],
      },
    );
    expect(find.byType(RevealOverlay), findsNothing);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    expect(find.byType(RevealOverlay), findsOneWidget);
    expect(find.text('Item a'), findsOneWidget);
  });

  testApp('tile map replaces the fallback once sheets load', (t) async {
    final sheets = (await t.runAsync(testSheets))!;
    await pumpApp(t, prefs: named, sheets: sheets);
    await t.pump();
    expect(find.byType(GameMapView), findsOneWidget);
  });

  testApp('missing tile assets keep a plain fallback', (t) async {
    await pumpApp(t, prefs: named);
    await t.pump();
    expect(find.byType(GameMapView), findsNothing);
    expect(t.takeException(), isNull);
  });
}
