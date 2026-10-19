import 'package:fogcatcher/l10n/generated/app_localizations.dart';
import 'package:fogcatcher/config/theme.dart';
import 'package:fogcatcher/map/game_map_view.dart';
import 'package:fogcatcher/map/markers_painter.dart';
import 'package:fogcatcher/map/sprite_sheets.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_sheets.dart';

Widget _app(
  SpriteSheets sheets, {
  void Function(GeoPoint)? onTapGeo,
  Key? key,
  bool withPlayer = true,
  GeoPoint? siteCenter,
  List<Chest<GeoPoint>>? chests,
}) {
  final proj = testProjection();
  return MaterialApp(
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
        key: key,
        map: testMap(),
        projection: proj,
        sheets: sheets,
        isRevealed: (fx, fy) => fx < 5,
        player: withPlayer ? proj.fromMeters(80, 80) : null,
        siteCenter: siteCenter,
        chests: chests ?? [(at: proj.fromMeters(60, 70), opened: true)],
        onTapGeo: onTapGeo,
      ),
    ),
  );
}

final _markers = find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is MarkersPainter,
);

final _pin = paints
  ..rect(color: AppColors.ink)
  ..rect(color: AppColors.ink)
  ..rect(color: AppColors.primary);

void main() {
  testWidgets('recenter button and attribution clear a 48 px nav bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.viewPadding = const FakeViewPadding(bottom: 48 * 3);
    addTearDown(tester.view.reset);
    final sheets = (await tester.runAsync(testSheets))!;
    await tester.pumpWidget(_app(sheets));
    final recenter = tester.getRect(find.byIcon(Icons.my_location));
    final attribution = tester.getRect(
      find.text('© OpenStreetMap contributors'),
    );
    expect(recenter.bottom, lessThanOrEqualTo(800 - 48));
    expect(attribution.bottom, lessThanOrEqualTo(800 - 48));
  });

  testWidgets('no player: camera centres on the site and a blue pin shows', (
    tester,
  ) async {
    final sheets = (await tester.runAsync(testSheets))!;
    final key = GlobalKey<GameMapViewState>();
    final center = testProjection().fromMeters(120, 40); // 30, 10 cells
    await tester.pumpWidget(
      _app(sheets, key: key, withPlayer: false, siteCenter: center),
    );
    final c = key.currentState!.debugCamera.centerCells;
    expect(c.dx, closeTo(30, 0.01));
    expect(c.dy, closeTo(10, 0.01));
    expect(tester.renderObject(_markers), _pin);
  });

  testWidgets('no pin once a player is on the map', (tester) async {
    final sheets = (await tester.runAsync(testSheets))!;
    final center = testProjection().fromMeters(120, 40);
    await tester.pumpWidget(_app(sheets, siteCenter: center));
    expect(tester.renderObject(_markers), isNot(_pin));
  });

  testWidgets('pumps without exceptions and shows the OSM attribution', (
    tester,
  ) async {
    final sheets = (await tester.runAsync(testSheets))!;
    await tester.pumpWidget(_app(sheets));
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
  });

  testWidgets('tap calls onTapGeo once with a point inside the map', (
    tester,
  ) async {
    final sheets = (await tester.runAsync(testSheets))!;
    final taps = <GeoPoint>[];
    await tester.pumpWidget(_app(sheets, onTapGeo: taps.add));
    await tester.tapAt(const Offset(400, 250));
    await tester.pump();
    expect(taps, hasLength(1));
    final m = testProjection().toMeters(taps.single);
    expect(m.x, inInclusiveRange(0, 160));
    expect(m.y, inInclusiveRange(0, 160));
  });

  testWidgets('pinch-out increases pxPerCell', (tester) async {
    final sheets = (await tester.runAsync(testSheets))!;
    final key = GlobalKey<GameMapViewState>();
    await tester.pumpWidget(_app(sheets, key: key));
    final before = key.currentState!.debugCamera.pxPerCell;
    final a = await tester.startGesture(const Offset(380, 300));
    final b = await tester.startGesture(const Offset(420, 300));
    await tester.pump();
    await a.moveTo(const Offset(300, 300));
    await b.moveTo(const Offset(500, 300));
    await tester.pump();
    await a.up();
    await b.up();
    await tester.pump();
    expect(key.currentState!.debugCamera.pxPerCell, greaterThan(before));
  });

  testWidgets('recenter button re-enables follow', (tester) async {
    final sheets = (await tester.runAsync(testSheets))!;
    final key = GlobalKey<GameMapViewState>();
    await tester.pumpWidget(_app(sheets, key: key));
    await tester.drag(find.byType(GameMapView), const Offset(60, 0));
    await tester.pump();
    expect(key.currentState!.debugCamera.followPlayer, isFalse);
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(key.currentState!.debugCamera.followPlayer, isTrue);
    expect(key.currentState!.debugCamera.centerCells.dx, closeTo(20, 1e-6));
  });

  testWidgets('pinch-in decreases pxPerCell', (tester) async {
    final sheets = (await tester.runAsync(testSheets))!;
    final key = GlobalKey<GameMapViewState>();
    await tester.pumpWidget(_app(sheets, key: key));
    final before = key.currentState!.debugCamera.pxPerCell;
    final a = await tester.startGesture(const Offset(300, 300));
    final b = await tester.startGesture(const Offset(500, 300));
    await tester.pump();
    await a.moveTo(const Offset(380, 300));
    await b.moveTo(const Offset(420, 300));
    await tester.pump();
    await a.up();
    await b.up();
    await tester.pump();
    expect(key.currentState!.debugCamera.pxPerCell, lessThan(before));
  });

  testWidgets('closed chests show only on revealed cells, found ones always', (
    tester,
  ) async {
    final sheets = (await tester.runAsync(testSheets))!;
    final proj = testProjection();
    // Revealed fog columns are fx < 5, i.e. x < 80 m.
    await tester.pumpWidget(
      _app(
        sheets,
        chests: [
          (at: proj.fromMeters(60, 70), opened: false),
          (at: proj.fromMeters(120, 90), opened: false),
          (at: proj.fromMeters(120, 40), opened: true),
        ],
      ),
    );
    final painter =
        tester.widget<CustomPaint>(_markers).painter! as MarkersPainter;
    expect(painter.chests, hasLength(2));
    expect(painter.chests[0].at.dx, closeTo(15, 1e-6));
    expect(painter.chests[0].opened, isFalse);
    expect(painter.chests[1].at.dx, closeTo(30, 1e-6));
    expect(painter.chests[1].opened, isTrue);
  });

  testWidgets('off-map taps are ignored', (tester) async {
    final sheets = (await tester.runAsync(testSheets))!;
    final taps = <GeoPoint>[];
    await tester.pumpWidget(_app(sheets, onTapGeo: taps.add));
    // Map is 400 px wide at zoom 10, centred on x=400: x=5 is off-map.
    await tester.tapAt(const Offset(5, 250));
    await tester.pump();
    expect(taps, isEmpty);
  });
}
