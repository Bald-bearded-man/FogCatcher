@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fogcatcher/config/theme.dart';
import 'package:fogcatcher/l10n/generated/app_localizations.dart';
import 'package:fogcatcher/widgets/score_card.dart';

Future<void> _loadFont(String family, String asset) async {
  final l = FontLoader(family)..addFont(rootBundle.load(asset));
  await l.load();
}

void main() {
  setUpAll(() async {
    await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
    await _loadFont('VT323', 'assets/fonts/VT323-Regular.ttf');
  });

  testWidgets('score card golden', (t) async {
    await t.binding.setSurfaceSize(const Size(360, 360));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.runAsync(() async {
      await t.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const RepaintBoundary(
            child: ScoreCard(
              data: ScoreCardData(
                playerName: 'Zoé',
                found: 5,
                total: 12,
                thumbnails: [
                  'assets/brand/logo.png',
                  'assets/brand/logo.png',
                  'assets/brand/logo.png',
                  'assets/brand/logo.png',
                  'assets/brand/logo.png',
                ],
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pump();
    await expectLater(
      find.byType(ScoreCard),
      matchesGoldenFile('score_card.png'),
    );
  });
}
