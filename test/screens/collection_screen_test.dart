import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fogcatcher/l10n/generated/app_localizations.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/item.dart';
import 'package:fogcatcher/screens/collection_screen.dart';
import 'package:fogcatcher/screens/item_detail_screen.dart';

Widget wrap(Widget w) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: w,
);

Item _item(String id) => Item(
  id: id,
  title: 'Title $id',
  text: 'Text $id',
  image: 'assets/missing/$id.png',
  position: const GeoPoint(0, 0),
);

void main() {
  setUpAll(() => initializeDateFormatting('en'));
  final items = [_item('a'), _item('b'), _item('c')];
  final found = {'a': DateTime(2030, 6, 1, 9, 0)};

  Widget screen({VoidCallback? onShare}) => wrap(
    CollectionScreen(items: items, found: found, onShare: onShare ?? () {}),
  );

  testWidgets('share button clears the system gesture bar', (t) async {
    t.view.physicalSize = const Size(360 * 3, 800 * 3);
    t.view.devicePixelRatio = 3;
    t.view.padding = const FakeViewPadding(bottom: 90);
    t.view.viewPadding = const FakeViewPadding(bottom: 90);
    addTearDown(t.view.reset);
    await t.pumpWidget(screen());
    final bottom = t.getBottomLeft(find.text('Share my score')).dy;
    expect(bottom, lessThanOrEqualTo(800 - 30));
  });

  testWidgets('shows found title, locked tiles and score', (t) async {
    await t.pumpWidget(screen());
    expect(find.text('Title a'), findsOneWidget);
    expect(find.text('???'), findsNWidgets(2));
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('tapping a found tile opens the detail', (t) async {
    await t.pumpWidget(screen());
    await t.tap(find.text('Title a'));
    await t.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
    expect(find.text('Text a'), findsOneWidget);
    expect(find.text('Found on Jun 1, 2030 at 09:00'), findsOneWidget);
  });

  testWidgets('tapping a locked tile does nothing', (t) async {
    await t.pumpWidget(screen());
    await t.tap(find.text('???').first);
    await t.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsNothing);
    expect(find.byType(CollectionScreen), findsOneWidget);
  });

  testWidgets('share button calls onShare once', (t) async {
    var n = 0;
    await t.pumpWidget(screen(onShare: () => n++));
    await t.tap(find.text('Share my score'));
    expect(n, 1);
  });

  testWidgets('missing image shows placeholder icon', (t) async {
    await t.pumpWidget(screen());
    await t.pump();
    expect(find.byIcon(Icons.inventory_2), findsWidgets);
    expect(t.takeException(), isNull);
  });
}
