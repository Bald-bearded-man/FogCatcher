import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fogcatcher/config/theme.dart';
import 'package:fogcatcher/l10n/generated/app_localizations.dart';
import 'package:fogcatcher/models/avatar.dart';
import 'package:fogcatcher/widgets/avatar_sprite.dart';
import 'package:fogcatcher/widgets/score_card.dart';
import 'package:fogcatcher/widgets/score_card_renderer.dart';

final _inkRgb = [
  for (final shift in [16, 8, 0]) AppColors.ink.toARGB32() >> shift & 0xFF,
];

void main() {
  testWidgets('renders a 1080x1080 PNG with the ink background painted', (
    t,
  ) async {
    await t.runAsync(() async {
      final png = await renderScoreCard(
        const ScoreCardData(
          playerName: 'Zoé',
          found: 1,
          total: 2,
          thumbnails: ['assets/missing/a.png'],
        ),
        locale: const Locale('en'),
      );
      final codec = await ui.instantiateImageCodec(png);
      final img = (await codec.getNextFrame()).image;
      expect((img.width, img.height), (1080, 1080));
      final px = (await img.toByteData())!;
      // Top-right corner is plain background.
      final o = (5 * 1080 + 1070) * 4;
      expect([px.getUint8(o), px.getUint8(o + 1), px.getUint8(o + 2)], _inkRgb);
      img.dispose();
    });
  });

  testWidgets('the shared PNG shows the avatar crisp next to the name', (
    t,
  ) async {
    const data = ScoreCardData(
      playerName: 'Zoé',
      avatar: Avatar.knight,
      found: 1,
      total: 2,
      thumbnails: [],
    );
    // Same layout as the renderer, to locate the sprite on the card.
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Align(
          alignment: Alignment.topLeft,
          child: ScoreCard(data: data),
        ),
      ),
    );
    final r = t.getRect(find.byType(AvatarSprite));
    expect(r.size, const Size.square(scoreCardAvatarSize));
    await t.runAsync(() async {
      final png = await renderScoreCard(data, locale: const Locale('en'));
      final img = (await (await ui.instantiateImageCodec(
        png,
      )).getNextFrame()).image;
      final px = (await img.toByteData())!;
      var painted = 0, total = 0;
      for (var y = r.top * 3; y < r.bottom * 3; y += 3) {
        for (var x = r.left * 3; x < r.right * 3; x += 3) {
          final o = (y.toInt() * 1080 + x.toInt()) * 4;
          total++;
          final rgb = px.getUint32(o) >> 8; // RGBA bytes
          if (rgb != AppColors.ink.toARGB32() & 0xFFFFFF) {
            painted++;
          }
        }
      }
      img.dispose();
      expect(painted / total, greaterThan(0.3));
    });
  });
}
