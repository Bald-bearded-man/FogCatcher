import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fogcatcher/l10n/generated/app_localizations.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/item.dart';
import 'package:fogcatcher/widgets/reveal_overlay.dart';

Item _item(String id) => Item(
  id: id,
  title: 'Title $id',
  text: 'Text $id',
  image: 'assets/missing/$id.png',
  position: const GeoPoint(0, 0),
);

Future<void> _pump(WidgetTester t, List<Item> q, VoidCallback onDone) =>
    t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RevealOverlay(queue: q, onDone: onDone),
        ),
      ),
    );

void main() {
  testWidgets('tap advances through the queue then calls onDone once', (
    t,
  ) async {
    var done = 0;
    await _pump(t, [_item('a'), _item('b')], () => done++);
    await t.pump(const Duration(seconds: 2));
    expect(find.text('Title a'), findsOneWidget);
    expect(find.text('Title b'), findsNothing);
    await t.tap(find.byType(RevealOverlay));
    await t.pump(const Duration(seconds: 2));
    expect(find.text('Title b'), findsOneWidget);
    expect(done, 0);
    await t.tap(find.byType(RevealOverlay));
    await t.pump();
    expect(done, 1);
  });

  testWidgets('auto-advances after 4 seconds', (t) async {
    var done = 0;
    await _pump(t, [_item('a'), _item('b')], () => done++);
    await t.pump(const Duration(seconds: 4));
    await t.pump(const Duration(seconds: 2));
    expect(find.text('Title b'), findsOneWidget);
    expect(done, 0);
    await t.pump(const Duration(seconds: 4));
    expect(done, 1);
  });

  testWidgets('empty queue calls onDone on the first frame', (t) async {
    var done = 0;
    await _pump(t, const [], () => done++);
    await t.pump();
    expect(done, 1);
  });
}
