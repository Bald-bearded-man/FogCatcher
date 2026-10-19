import 'package:fogcatcher/config/constants.dart';
import 'package:fogcatcher/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (size, side, font) in [
    (AppLogoSize.large, 96.0, 22.0),
    (AppLogoSize.compact, 24.0, 10.0),
  ]) {
    testWidgets('$size shows logo and title', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: AppLogo(size: size)),
          ),
        ),
      );
      expect(t.widget<Text>(find.text(appTitle)).style!.fontSize, font);
      final img = t.widget<Image>(find.byType(Image));
      expect(img.width, side);
      expect(img.filterQuality, FilterQuality.none);
      expect((img.image as AssetImage).assetName, appLogoAsset);
      expect(img.semanticLabel, appTitle);
    });
  }
}
