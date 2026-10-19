import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/constants.dart';
import 'config/licenses.dart';
import 'config/theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers/providers.dart';
import 'screens/startup_router.dart';
import 'services/content_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerAssetLicenses(rootBundle);
  final prefs = await SharedPreferences.getInstance();
  final content = await ContentRepository(rootBundle).loadAll();
  final container = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      contentProvider.overrideWithValue(content),
    ],
  );
  try {
    await container.read(notifierProvider).init();
  } catch (e) {
    // The game still works without notifications.
    debugPrint('Notifier init failed: $e');
  }
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FogCatcherApp(),
    ),
  );
}

class FogCatcherApp extends StatelessWidget {
  const FogCatcherApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: appTitle,
    theme: buildTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: const StartupRouter(),
  );
}
