import 'package:fogcatcher/config/constants.dart';
import 'package:fogcatcher/config/pack.g.dart';
import 'package:fogcatcher/config/theme.dart';
import 'package:fogcatcher/screens/startup_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../screens/app_harness.dart';

void main() {
  testWidgets('app is English, titled, and routes from StartupRouter', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, appTitle);
    expect(app.locale, const Locale('en'));
    expect(app.home, isA<StartupRouter>());
    expect(h.source.starts, 0);
  });
  test('app constants come from the content pack', () {
    expect(appTitle, packAppName);
    expect(eventEnd, packEventEnd);
    expect(defaultSiteId, packDefaultSiteId);
  });
  test('theme is dark on ink with square buttons', () {
    final t = buildTheme();
    expect(t.scaffoldBackgroundColor, AppColors.ink);
    expect(t.colorScheme.primary, AppColors.primary);
  });
}
