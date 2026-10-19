import 'package:fogcatcher/config/theme.dart';
import 'package:fogcatcher/map/game_map_view.dart';
import 'package:fogcatcher/models/avatar.dart';
import 'package:fogcatcher/screens/avatar_screen.dart';
import 'package:fogcatcher/widgets/avatar_sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../map/test_sheets.dart';
import 'app_harness.dart';

const named = {'player.name': 'Ana'};

Finder tile(Avatar a) => find.byKey(ValueKey('avatar-${a.name}'));

Color borderOf(WidgetTester t, Avatar a) {
  final box = t.widget<Container>(
    find.descendant(of: tile(a), matching: find.byType(Container)).first,
  );
  return ((box.decoration! as BoxDecoration).border! as Border).top.color;
}

void main() {
  testApp('menu opens the grid with every avatar and big tap targets', (
    t,
  ) async {
    await pumpApp(t, prefs: named);
    await openMenuItem(t, 'Choose avatar');
    expect(find.byType(AvatarScreen), findsOneWidget);
    for (final a in Avatar.values) {
      final size = t.getSize(tile(a));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(find.text('Astronaut'), findsOneWidget);
    expect(borderOf(t, Avatar.knight), AppColors.primary);
  });

  testApp('tapping an avatar selects, highlights and saves it', (t) async {
    final h = await pumpApp(t, prefs: named);
    await openMenuItem(t, 'Choose avatar');
    await t.tap(tile(Avatar.mage));
    await t.pump();
    expect(h.prefs.getString('player.avatar'), 'mage');
    expect(borderOf(t, Avatar.mage), AppColors.primary);
    expect(borderOf(t, Avatar.knight), isNot(AppColors.primary));
  });

  testApp('grid animates between the idle and bob frames', (t) async {
    await pumpApp(t, prefs: named);
    await openMenuItem(t, 'Choose avatar');
    int bob() => t
        .widget<AvatarSprite>(
          find.descendant(
            of: tile(Avatar.slime),
            matching: find.byType(AvatarSprite),
          ),
        )
        .bob;
    final first = bob();
    await t.pump(const Duration(milliseconds: 300));
    expect(bob(), 1 - first);
  });

  testApp('the map marker follows the chosen avatar', (t) async {
    final sheets = (await t.runAsync(testSheets))!;
    await pumpApp(t, prefs: named, sheets: sheets);
    await settle(t);
    expect(
      t.widget<GameMapView>(find.byType(GameMapView)).avatar,
      Avatar.knight,
    );
    await openMenuItem(t, 'Choose avatar');
    await t.tap(tile(Avatar.robot));
    await t.pump();
    await t.pageBack();
    await settle(t);
    expect(
      t.widget<GameMapView>(find.byType(GameMapView)).avatar,
      Avatar.robot,
    );
  });
}
