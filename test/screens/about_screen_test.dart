import 'package:fogcatcher/screens/about_screen.dart';
import 'package:fogcatcher/widgets/app_logo.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

void main() {
  testApp('About shows the pack logo, not a plain title', (t) async {
    await pumpApp(t, prefs: const {'player.name': 'Ana'});
    await openMenuItem(t, 'About');
    final logo = find.descendant(
      of: find.byType(AboutScreen),
      matching: find.byType(AppLogo),
    );
    expect(logo, findsOneWidget);
    expect(t.widget<AppLogo>(logo).size, AppLogoSize.large);
  });

  testApp('About credits OpenStreetMap', (t) async {
    await pumpApp(t, prefs: const {'player.name': 'Ana'});
    await openMenuItem(t, 'About');
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
  });
}
