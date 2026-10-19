import 'dart:math';

import 'package:clock/clock.dart';
import 'package:fogcatcher/config/constants.dart';
import 'package:fogcatcher/game/fog_grid.dart';
import 'package:fogcatcher/game/game_phase.dart';
import 'package:fogcatcher/models/avatar.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/providers/game_controller.dart';
import 'package:fogcatcher/services/content_repository.dart';
import 'package:fogcatcher/services/progress_repository.dart';
import 'package:fogcatcher/services/simulated_position_source.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes.dart';

final playing = eventEnd.subtract(const Duration(days: 4));
const otherOrigin = GeoPoint(43.70, 7.10);

void main() {
  late ProgressRepository repo;
  late FakePositionSource fake;
  late SwitchablePositionSource source;
  late FakeNotifier notifier;
  late bool foreground;
  GameController? controller;

  final itemA = testItemPoint(demoOrigin, 0);
  final itemB = testItemPoint(demoOrigin, 1);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = ProgressRepository(await SharedPreferences.getInstance());
    fake = FakePositionSource();
    source = SwitchablePositionSource(fake, SimulatedPositionSource());
    notifier = FakeNotifier();
    foreground = true;
    controller = null;
  });

  tearDown(() {
    if (controller?.mounted ?? false) controller!.dispose();
  });

  GameController make({
    List<SiteBundle>? sites,
    DateTime? now,
    Clock? clk,
    Random? random,
  }) {
    final c = withClock(
      clk ?? Clock.fixed(now ?? playing),
      () => GameController(
        repo: repo,
        sites: sites ?? [testBundle()],
        source: source,
        notifier: notifier,
        isForeground: () => foreground,
        random: random,
      ),
    );
    return controller = c;
  }

  void fixOn(GameController c, GeoPoint p, {double accuracy = 5}) => withClock(
    Clock.fixed(playing),
    () => c.onFix(fixAt(p, accuracy: accuracy)),
  );

  test(
    'accepted fix on an item finds it, persists it and plays reveal in foreground',
    () async {
      final c = make();
      fixOn(c, itemA);
      await pumpEventQueue();
      expect(c.state.found, {'a': playing});
      expect(repo.load('demo_park').found, {'a': playing});
      expect(c.state.unseen, ['a']);
      expect(repo.load('demo_park').unseen, ['a']);
      expect(notifier.shown, isEmpty);
      expect(c.state.lastFix?.point, itemA);
    },
  );

  test('background find posts a notification and queues unseen', () async {
    foreground = false;
    final c = make();
    fixOn(c, itemA);
    await pumpEventQueue();
    expect(notifier.shown, ['a']);
    expect(c.state.unseen, ['a']);
  });

  test(
    'a 40 m fix reveals fog and moves the player but finds no item',
    () async {
      final c = make();
      fixOn(c, itemA, accuracy: 40);
      await pumpEventQueue();
      expect(c.state.found, isEmpty);
      expect(c.state.fog.revealedCount, greaterThan(0));
      expect(c.state.lastFix?.point, itemA);
    },
  );

  test('a 25 m fix finds the item', () async {
    final c = make();
    fixOn(c, itemA, accuracy: 25);
    await pumpEventQueue();
    expect(c.state.found.keys, ['a']);
  });

  test('inaccurate fix changes nothing', () async {
    final c = make();
    fixOn(c, itemA, accuracy: 51);
    await pumpEventQueue();
    expect(c.state.found, isEmpty);
    expect(c.state.fog.revealedCount, 0);
    expect(c.state.fogVersion, 0);
    expect(c.state.lastFix?.accuracyMeters, 51);
  });

  test(
    'fix far from every site keeps the active site and changes nothing',
    () async {
      await repo.setActiveSiteId('other');
      final c = make(
        sites: [
          testBundle(),
          testBundle(id: 'other', origin: otherOrigin),
        ],
      );
      expect(c.state.siteId, 'other');
      fixOn(c, parisPoint);
      await pumpEventQueue();
      expect(c.state.siteId, 'other');
      expect(repo.activeSiteId, 'other');
      expect(c.state.found, isEmpty);
      expect(c.state.fog.revealedCount, 0);
      expect(c.state.unseen, isEmpty);
    },
  );

  test('fog reveal persists after debounce', () {
    fakeAsync((async) {
      withClock(async.getClock(playing), () {
        final c = make();
        c.onFix(fixAt(itemA));
        async.flushMicrotasks();
        expect(c.state.fogVersion, 1);
        expect(c.state.fog.revealedCount, greaterThan(0));
        expect(repo.load('demo_park').fogBytes, isNull);
        async.elapse(const Duration(seconds: 10));
        final bytes = repo.load('demo_park').fogBytes;
        expect(bytes, isNotNull);
        final saved = FogGrid.fromBytes(
          c.state.fog.width,
          c.state.fog.height,
          bytes!,
        );
        expect(saved.revealedCount, c.state.fog.revealedCount);
        c.dispose();
      });
    });
  });

  test('a fix over already revealed fog does not bump fogVersion', () async {
    final c = make();
    fixOn(c, itemB);
    fixOn(c, itemB);
    await pumpEventQueue();
    expect(c.state.fogVersion, 1);
  });

  test('ended phase stops a running position source', () async {
    await repo.setExploring(true);
    fake.running = true;
    final c = make(now: eventEnd.add(const Duration(days: 1)));
    await pumpEventQueue();
    expect(c.state.phase, GamePhase.ended);
    expect(fake.stops, 1);
    expect(fake.running, isFalse);
    expect(repo.exploring, isFalse);
    expect(c.state.exploring, isFalse);

    await c.startExploring();
    expect(fake.running, isFalse);
    expect(fake.starts, 0);
    expect(repo.exploring, isFalse);

    // onFix re-reads the clock, so the fix must come after the end too.
    withClock(
      Clock.fixed(eventEnd.add(const Duration(days: 1))),
      () => c.onFix(fixAt(itemA)),
    );
    await pumpEventQueue();
    expect(c.state.found, isEmpty);
  });

  test('phase timer switches to ended and stops the source', () {
    fakeAsync((async) {
      final start = eventEnd.subtract(const Duration(seconds: 29));
      withClock(async.getClock(start), () {
        final c = make(clk: clock);
        c.startExploring();
        async.flushMicrotasks();
        expect(fake.running, isTrue);
        expect(c.state.phase, GamePhase.playing);
      });
      // Timers fire in their creation zone, so the fake clock still applies.
      async.elapse(const Duration(seconds: 60));
      expect(controller!.state.phase, GamePhase.ended);
      expect(controller!.state.exploring, isFalse);
      expect(fake.running, isFalse);
      expect(repo.exploring, isFalse);
      controller!.dispose();
    });
  });

  test('startExploring persists exploring flag and starts source', () async {
    final c = make();
    expect(c.state.exploring, isFalse);
    await c.startExploring();
    expect(fake.running, isTrue);
    expect(fake.starts, 1);
    expect(repo.exploring, isTrue);
    expect(c.state.exploring, isTrue);
  });

  test('pauseExploring stops it', () async {
    final c = make();
    await c.startExploring();
    await c.pauseExploring();
    expect(fake.running, isFalse);
    expect(repo.exploring, isFalse);
    expect(c.state.exploring, isFalse);
  });

  test('pauseExploring flushes revealed fog', () async {
    final c = make();
    fixOn(c, itemA);
    await c.pauseExploring();
    expect(repo.load('demo_park').fogBytes, isNotNull);
  });

  test('notification tap moves item to front of unseen', () async {
    final c = make();
    fixOn(c, itemA);
    fixOn(c, itemB);
    await pumpEventQueue();
    expect(c.state.unseen, ['a', 'b']);
    notifier.tap('b');
    await pumpEventQueue();
    expect(c.state.unseen, ['b', 'a']);
    expect(repo.load('demo_park').unseen, ['b', 'a']);
    notifier.tap('unknown');
    await pumpEventQueue();
    expect(c.state.unseen, ['b', 'a']);
  });

  test('launch notification item goes to the front of unseen', () async {
    await repo.saveFound('demo_park', {'a': playing, 'b': playing});
    await repo.saveUnseen('demo_park', ['b']);
    notifier.launchItemId = 'a';
    final c = make();
    expect(c.state.unseen, ['a', 'b']);
    expect(notifier.launchItemId, isNull);
  });

  test('launch item that is not found is ignored', () async {
    notifier.launchItemId = 'a';
    final c = make();
    expect(c.state.unseen, isEmpty);
  });

  test(
    'debug teleport routes simulated fixes through the same pipeline',
    () async {
      final c = make();
      c.teleport(itemA);
      await pumpEventQueue();
      expect(c.state.found, isEmpty, reason: 'teleport needs debug');

      await c.setDebug(true);
      expect(repo.debugEnabled, isTrue);
      withClock(Clock.fixed(playing), () => c.teleport(itemA));
      await pumpEventQueue();
      expect(c.state.found.keys, ['a']);
      expect(c.state.lastFix?.simulated, isTrue);
      expect(source.useSimulated, isTrue);

      await c.setDebug(false);
      expect(source.useSimulated, isFalse);
    },
  );

  test(
    'resetProgress clears found, fog and unseen for the active site only',
    () async {
      await repo.saveFound('other', {'x': playing});
      final c = make(
        sites: [
          testBundle(),
          testBundle(id: 'other', origin: otherOrigin),
        ],
      );
      fixOn(c, itemA);
      await pumpEventQueue();
      await c.pauseExploring(); // flushes fog
      expect(repo.load('demo_park').fogBytes, isNotNull);

      await c.resetProgress();
      expect(c.state.found, isEmpty);
      expect(c.state.unseen, isEmpty);
      expect(c.state.fog.revealedCount, 0);
      final p = repo.load('demo_park');
      expect(p.found, isEmpty);
      expect(p.fogBytes, isNull);
      expect(p.unseen, isEmpty);
      expect(repo.load('other').found, {'x': playing});
    },
  );

  test('two items in range of one teleport are both found in order', () async {
    foreground = false;
    final c = make(sites: [testBundle(spacing: 10, radius: 20)]);
    await c.setDebug(true);
    withClock(
      Clock.fixed(playing),
      () => c.teleport(testItemPoint(demoOrigin, 0, spacing: 5)),
    );
    await pumpEventQueue();
    expect(c.state.found.keys, ['a', 'b']);
    expect(c.state.unseen, ['a', 'b']);
    expect(notifier.shown, ['a', 'b']);
  });

  test(
    'fix inside another site switches and persists the active site',
    () async {
      await repo.saveFound('other', {'b': playing});
      final c = make(
        sites: [
          testBundle(),
          testBundle(id: 'other', origin: otherOrigin),
        ],
      );
      expect(c.state.siteId, 'demo_park');
      fixOn(c, testItemPoint(otherOrigin, 0));
      await pumpEventQueue();
      expect(c.state.siteId, 'other');
      expect(repo.activeSiteId, 'other');
      expect(c.state.found.keys, unorderedEquals(['a', 'b']));
      expect(repo.load('other').found.keys, unorderedEquals(['a', 'b']));
      expect(repo.load('demo_park').found, isEmpty);
    },
  );

  test('unknown stored site falls back to the first bundle', () async {
    await repo.setActiveSiteId('gone');
    final c = make(sites: [testBundle(id: 'only')]);
    expect(c.state.siteId, 'only');
    expect(c.state.bundleOf([testBundle(id: 'only')]).site.id, 'only');
  });

  test('markSeen removes ids from unseen and persists', () async {
    final c = make();
    fixOn(c, itemA);
    fixOn(c, itemB);
    await pumpEventQueue();
    await c.markSeen(['a']);
    expect(c.state.unseen, ['b']);
    expect(repo.load('demo_park').unseen, ['b']);
  });

  test('setPlayerName persists and updates state', () async {
    final c = make();
    expect(c.state.playerName, isNull);
    await c.setPlayerName('Ana');
    expect(c.state.playerName, 'Ana');
    expect(repo.playerName, 'Ana');
  });

  test('syncExploring catches up when the source stopped itself', () async {
    final c = make();
    await c.startExploring();
    c.syncExploring();
    expect(c.state.exploring, isTrue);
    fake.running = false;
    c.syncExploring();
    expect(c.state.exploring, isFalse);
    expect(c.state.locationLost, isTrue);
    await pumpEventQueue();
    expect(repo.exploring, isFalse);
    await c.startExploring();
    expect(c.state.locationLost, isFalse);
    expect(c.state.exploring, isTrue);
  });

  test('a source error stops exploring at once', () async {
    final c = make();
    await c.startExploring();
    fake.lose();
    await pumpEventQueue();
    expect(c.state.exploring, isFalse);
    expect(c.state.locationLost, isTrue);
  });

  test('a source that fails on start never shows as exploring', () async {
    final c = make();
    fake.failOnStart = true;
    await c.startExploring();
    expect(c.state.exploring, isFalse);
    expect(c.state.locationLost, isTrue);
  });

  test('the minute timer notices a silent stop', () {
    fakeAsync((async) {
      withClock(async.getClock(playing), () {
        final c = make(clk: clock);
        c.startExploring();
        async.flushMicrotasks();
        fake.running = false;
      });
      async.elapse(const Duration(minutes: 1));
      expect(controller!.state.exploring, isFalse);
      expect(controller!.state.locationLost, isTrue);
      controller!.dispose();
    });
  });

  test('pause clears the lost-location flag', () async {
    final c = make();
    await c.startExploring();
    fake.running = false;
    c.syncExploring();
    await c.pauseExploring();
    expect(c.state.locationLost, isFalse);
  });

  test(
    'reopening after a process death flags it and does not restart',
    () async {
      await repo.setExploring(true);
      final c = make();
      expect(c.state.exploring, isFalse);
      expect(c.state.interrupted, isTrue);
      expect(fake.starts, 0);
      await c.startExploring();
      expect(c.state.interrupted, isFalse);
    },
  );

  test('no interruption flag when exploring was not on', () {
    expect(make().state.interrupted, isFalse);
  });

  test(
    'a fix 1 s after the deadline finds nothing, even with a stale phase',
    () async {
      final c = make(now: eventEnd.subtract(const Duration(seconds: 59)));
      expect(c.state.phase, GamePhase.playing);
      withClock(
        Clock.fixed(eventEnd.add(const Duration(seconds: 1))),
        () => c.onFix(fixAt(itemA)),
      );
      await pumpEventQueue();
      expect(c.state.phase, GamePhase.ended);
      expect(c.state.found, isEmpty);
      expect(repo.load('demo_park').found, isEmpty);
    },
  );

  test('first opening picks a seeded random avatar and saves it', () async {
    // Random(0).nextInt(10) == 5, Random(5).nextInt(10) == 8.
    final c = make(random: Random(0));
    expect(c.state.avatar, Avatar.robot);
    expect(repo.avatar, Avatar.robot);
    c.dispose();
    SharedPreferences.setMockInitialValues({});
    repo = ProgressRepository(await SharedPreferences.getInstance());
    final d = make(random: Random(5));
    expect(d.state.avatar, Avatar.astronaut);
    expect(repo.avatar, Avatar.astronaut);
  });

  test('a stored avatar is never replaced by a random one', () async {
    await repo.setAvatar(Avatar.mage);
    for (var seed = 0; seed < 10; seed++) {
      expect(make(random: Random(seed)).state.avatar, Avatar.mage);
      controller!.dispose();
    }
    expect(repo.avatar, Avatar.mage);
  });

  test('a corrupt stored avatar falls back to the adventurer', () async {
    SharedPreferences.setMockInitialValues({'player.avatar': 'dragon'});
    repo = ProgressRepository(await SharedPreferences.getInstance());
    expect(make(random: Random(0)).state.avatar, Avatar.explorerBoy);
  });

  test('avatar loads from the store and setAvatar persists it', () async {
    await repo.setAvatar(Avatar.knight);
    final c = make();
    expect(c.state.avatar, Avatar.knight);
    await c.setAvatar(Avatar.slime);
    expect(c.state.avatar, Avatar.slime);
    expect(repo.avatar, Avatar.slime);
  });

  test('phase override forces ended then playing', () async {
    final c = make();
    await c.startExploring();
    await c.setDebug(true);
    c.setPhaseOverride(PhaseOverride.ended);
    await pumpEventQueue();
    expect(c.state.phase, GamePhase.ended);
    expect(c.state.phaseOverride, PhaseOverride.ended);
    expect(fake.running, isFalse);
    expect(repo.exploring, isFalse);

    withClock(Clock.fixed(playing), () {
      c.setPhaseOverride(PhaseOverride.playing);
    });
    expect(c.state.phase, GamePhase.playing);

    await c.setDebug(false);
    expect(c.state.phaseOverride, PhaseOverride.auto);
  });

  test('forceFind adds the item as found and unseen in debug only', () async {
    final c = make();
    await c.forceFind('b');
    expect(c.state.found, isEmpty);
    await c.setDebug(true);
    await withClock(Clock.fixed(playing), () => c.forceFind('b'));
    await c.forceFind('nope');
    expect(c.state.found, {'b': playing});
    expect(c.state.unseen, ['b']);
    expect(repo.load('demo_park').found, {'b': playing});
  });

  test('forceSite switches the active site in debug only', () async {
    final c = make(
      sites: [
        testBundle(),
        testBundle(id: 'other', origin: otherOrigin),
      ],
    );
    await c.forceSite('other');
    expect(c.state.siteId, 'demo_park');
    await c.setDebug(true);
    await c.forceSite('nope');
    expect(c.state.siteId, 'demo_park');
    await c.forceSite('other');
    expect(c.state.siteId, 'other');
    expect(repo.activeSiteId, 'other');
  });

  test('restores found, unseen and fog from storage', () async {
    final first = make();
    fixOn(first, itemA);
    await pumpEventQueue();
    first.dispose();
    final c = make();
    expect(c.state.found.keys, ['a']);
    expect(c.state.unseen, ['a']);
    expect(c.state.fog.revealedCount, greaterThan(0));
  });
}
