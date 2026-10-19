import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fogcatcher/config/constants.dart';
import 'package:fogcatcher/config/pack.g.dart';
import 'package:fogcatcher/l10n/generated/app_localizations.dart';
import 'package:fogcatcher/models/avatar.dart';
import 'package:fogcatcher/widgets/avatar_sprite.dart';
import 'package:fogcatcher/widgets/app_logo.dart';
import 'package:fogcatcher/widgets/score_card.dart';

Widget wrap(Widget w) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: Center(child: w)),
);

ScoreCardData data(int thumbs, {String name = 'Zoé'}) => ScoreCardData(
  playerName: name,
  found: 5,
  total: 12,
  thumbnails: [for (var i = 0; i < thumbs; i++) 'assets/missing/$i.png'],
);

void main() {
  testWidgets('14 thumbnails show 12 images and +2', (t) async {
    await t.pumpWidget(wrap(ScoreCard(data: data(14))));
    expect(find.byKey(const ValueKey('score-thumb')), findsNWidgets(12));
    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('footer credits the developer', (t) async {
    await t.pumpWidget(wrap(ScoreCard(data: data(14))));
    expect(find.text('Developed by BaldMan'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('shows logo, player, score and event', (t) async {
    await t.pumpWidget(wrap(ScoreCard(data: data(3))));
    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text(appTitle), findsOneWidget);
    expect(find.text('Zoé'), findsOneWidget);
    expect(find.text('5 / 12 items'), findsOneWidget);
    expect(find.text(packEventLine), findsOneWidget);
    expect(find.text('+2'), findsNothing);
  });

  testWidgets('every logo image on the card is drawn unsmoothed', (t) async {
    await t.pumpWidget(wrap(ScoreCard(data: data(0))));
    String? asset(ImageProvider p) => switch (p) {
      AssetImage(:final assetName) => assetName,
      ResizeImage(imageProvider: AssetImage(:final assetName)) => assetName,
      _ => null,
    };
    final logos = t
        .widgetList<Image>(find.byType(Image))
        .where((i) => asset(i.image) == appLogoAsset)
        .toList();
    expect(logos, hasLength(2)); // header logo + backdrop
    expect(logos.map((i) => i.filterQuality), everyElement(FilterQuality.none));
  });

  testWidgets('shows the avatar at 64 px left of the name', (t) async {
    const d = ScoreCardData(
      playerName: 'Zoé',
      avatar: Avatar.astronaut,
      found: 1,
      total: 2,
      thumbnails: [],
    );
    await t.pumpWidget(wrap(const ScoreCard(data: d)));
    final sprite = find.byType(AvatarSprite);
    expect(t.widget<AvatarSprite>(sprite).avatar, Avatar.astronaut);
    expect(t.getSize(sprite), const Size(64, 64));
    expect(t.getRect(sprite).right, lessThan(t.getRect(find.text('Zoé')).left));
  });

  testWidgets('empty name falls back to anonymous player', (t) async {
    await t.pumpWidget(wrap(ScoreCard(data: data(0, name: '  '))));
    expect(find.text('Mystery adventurer'), findsOneWidget);
  });
}
