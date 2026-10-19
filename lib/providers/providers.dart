import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../l10n/app_strings.dart';
import '../game/debug_pin.dart';
import '../map/sprite_sheets.dart';
import '../services/content_repository.dart';
import '../services/geolocator_position_source.dart';
import '../services/interfaces.dart';
import '../services/local_item_notifier.dart';
import '../services/plugin_system_settings.dart';
import '../services/progress_repository.dart';
import '../services/share_plus_sharer.dart';
import '../services/simulated_position_source.dart';
import 'game_controller.dart';

// Overridden in main() once SharedPreferences is loaded.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError(),
);

final progressRepositoryProvider = Provider(
  (ref) => ProgressRepository(ref.watch(sharedPrefsProvider)),
);

// Overridden in main() once the site assets are loaded.
final contentProvider = Provider<List<SiteBundle>>(
  (_) => throw UnimplementedError(),
);

final realPositionSourceProvider = Provider<PositionSource>(
  (_) => GeolocatorPositionSource(
    notificationTitle: appStrings.exploringNotificationTitle(appTitle),
    notificationText: appStrings.exploringNotificationBody,
    channelName: appStrings.explorationChannel,
  ),
);

final simulatedPositionSourceProvider = Provider(
  (_) => SimulatedPositionSource(),
);

final positionSourceProvider = Provider<SwitchablePositionSource>(
  (ref) => SwitchablePositionSource(
    ref.watch(realPositionSourceProvider),
    ref.watch(simulatedPositionSourceProvider),
  ),
);

final notifierProvider = Provider<ItemFoundNotifier>(
  (_) => LocalItemNotifier(),
);

final sharerProvider = Provider<ScoreSharer>((_) => SharePlusSharer());

final systemSettingsProvider = Provider<SystemSettings>(
  (_) => PluginSystemSettings(),
);

// Fails when the tile assets are missing; the map then shows a plain fallback.
final spriteSheetsProvider = FutureProvider<SpriteSheets>(
  (_) => SpriteSheets.load(rootBundle),
);

// Hash of the debug PIN, from --dart-define; empty disables the debug menu.
final debugPinGateProvider = Provider(
  (_) => DebugPinGate(const String.fromEnvironment('DEBUG_PIN_SHA256')),
);

// Seeds the first-opening avatar; tests override it with a seeded Random.
final randomProvider = Provider<Random>((_) => Random());

final gameControllerProvider = StateNotifierProvider<GameController, GameState>(
  (ref) => GameController(
    repo: ref.watch(progressRepositoryProvider),
    sites: ref.watch(contentProvider),
    source: ref.watch(positionSourceProvider),
    notifier: ref.watch(notifierProvider),
    isForeground: isAppInForeground,
    random: ref.watch(randomProvider),
  ),
);

/// Null before the first frame, when the app is opening in front of the player.
bool isAppInForeground() {
  final s = WidgetsBinding.instance.lifecycleState;
  return s == null || s == AppLifecycleState.resumed;
}
