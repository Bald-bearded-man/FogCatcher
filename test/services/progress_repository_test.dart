import 'dart:typed_data';
import 'package:fogcatcher/models/avatar.dart';
import 'package:fogcatcher/services/progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressRepository> repo([Map<String, Object> init = const {}]) async {
  SharedPreferences.setMockInitialValues(init);
  return ProgressRepository(await SharedPreferences.getInstance());
}

void main() {
  test('empty store yields empty progress', () async {
    final p = (await repo()).load('demo_park');
    expect(p.found, isEmpty);
    expect(p.fogBytes, isNull);
    expect(p.unseen, isEmpty);
  });
  test('found, fog and unseen round-trip', () async {
    final r = await repo();
    await r.saveFound('s', {'o01': DateTime.utc(2030, 6, 1, 9)});
    await r.saveFog('s', Uint8List.fromList([1, 2, 3]));
    await r.saveUnseen('s', ['o01']);
    final p = r.load('s');
    expect(p.found['o01'], DateTime.utc(2030, 6, 1, 9));
    expect(p.fogBytes, [1, 2, 3]);
    expect(p.unseen, ['o01']);
  });
  test('load tolerates corrupt fog and found entries', () async {
    final r = await repo({
      'progress.s.found': '{not json',
      'progress.s.fog': '%%%',
      'progress.s.unseen': '7',
    });
    final p = r.load('s');
    expect(p.found, isEmpty);
    expect(p.fogBytes, isNull);
    expect(p.unseen, isEmpty);
  });
  test('sites are isolated and reset clears one site', () async {
    final r = await repo();
    await r.saveFound('a', {'x': DateTime.utc(2030)});
    await r.saveFound('b', {'y': DateTime.utc(2030)});
    await r.reset('a');
    expect(r.load('a').found, isEmpty);
    expect(r.load('b').found.keys, ['y']);
  });
  test('player name, active site, debug and exploring flags persist', () async {
    final r = await repo();
    await r.setPlayerName('Ana');
    await r.setActiveSiteId('test_site');
    await r.setDebugEnabled(true);
    await r.setExploring(true);
    expect(
      [r.playerName, r.activeSiteId, r.debugEnabled, r.exploring],
      ['Ana', 'test_site', true, true],
    );
  });
  test(
    'avatar defaults, round-trips by name and survives corruption',
    () async {
      final r = await repo();
      expect(r.avatar, Avatar.explorerBoy);
      expect(r.hasAvatar, isFalse);
      await r.setAvatar(Avatar.pirate);
      expect(r.hasAvatar, isTrue);
      expect(r.avatar, Avatar.pirate);
      expect((await repo({'player.avatar': 'pirate'})).avatar, Avatar.pirate);
      expect(
        (await repo({'player.avatar': 'dragon'})).avatar,
        Avatar.explorerBoy,
      );
      expect((await repo({'player.avatar': 7})).avatar, Avatar.explorerBoy);
    },
  );
  test('copyWith replaces only given parts', () {
    final p = const SiteProgress(
      unseen: ['a'],
    ).copyWith(found: {'x': DateTime.utc(2030)});
    expect(p.unseen, ['a']);
    expect(p.found.keys, ['x']);
  });
}
