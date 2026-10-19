@Tags(['golden'])
library;

import 'package:fogcatcher/l10n/generated/app_localizations.dart';
import 'package:fogcatcher/map/game_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_sheets.dart';

void main() {
  testWidgets('fog over tilemap golden', (tester) async {
    tester.view.physicalSize = const Size(320, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sheets = (await tester.runAsync(testSheets))!;
    final proj = testProjection();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GameMapView(
            map: testMap(),
            projection: proj,
            sheets: sheets,
            isRevealed: (fx, fy) => fx < 5,
            player: proj.fromMeters(80, 80),
            chests: [
              (at: proj.fromMeters(60, 70), opened: true),
              (at: proj.fromMeters(100, 90), opened: true),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(GameMapView),
      matchesGoldenFile('fog_tilemap.png'),
    );
  });
}
