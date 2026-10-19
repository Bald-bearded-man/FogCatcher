// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get onboardingNameTitle => 'What is your name, adventurer?';

  @override
  String get onboardingNameHint => 'Your first name';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingLocationTitle => 'The map needs your location';

  @override
  String get onboardingLocationBody =>
      'Your location reveals the map and finds items. It never leaves your phone.';

  @override
  String get onboardingLocationButton => 'Allow location';

  @override
  String get onboardingLocationDenied =>
      'Without your location you can\'t explore. Open settings to allow it.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get onboardingNotifTitle => 'Get notified of finds';

  @override
  String get onboardingNotifBody =>
      'A notification tells you when you find an item, even with the screen off.';

  @override
  String get onboardingNotifButton => 'Allow notifications';

  @override
  String get onboardingBatteryTitle => 'Keep exploring in the background';

  @override
  String onboardingBatteryBody(String appName) {
    return 'Choose \"Unrestricted\" for $appName and don\'t close the app: leave it in the background.';
  }

  @override
  String get onboardingBatteryButton => 'Open battery settings';

  @override
  String get onboardingStart => 'Let\'s go!';

  @override
  String get skip => 'Skip';

  @override
  String get startExploring => 'Start exploring';

  @override
  String get pauseExploring => 'Stop exploring';

  @override
  String get stopExploringTitle => 'Stop exploring?';

  @override
  String get stopExploringBody =>
      'Location tracking will stop. You won\'t find items or reveal the map until you tap Start exploring again.';

  @override
  String get stopExploringConfirm => 'Stop';

  @override
  String exploringNotificationTitle(String appName) {
    return '$appName — exploring';
  }

  @override
  String get exploringNotificationBody =>
      'Keep the app open in the background to find items.';

  @override
  String get itemFoundTitle => 'Item found!';

  @override
  String score(int found, int total) {
    return '$found / $total';
  }

  @override
  String get collectionTitle => 'My loot';

  @override
  String get lockedItem => '???';

  @override
  String foundAt(String date) {
    return 'Found on $date';
  }

  @override
  String get shareScore => 'Share my score';

  @override
  String shareCaption(int found, int total, String appName) {
    return 'I found $found of $total items in $appName 🗺️';
  }

  @override
  String scoreCardItems(int found, int total) {
    return '$found / $total items';
  }

  @override
  String get gameOverTitle => 'The adventure is over!';

  @override
  String get gameOverBody => 'Thanks for playing. Share your score!';

  @override
  String get menuCollection => 'My loot';

  @override
  String get menuAbout => 'About';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get osmAttribution => '© OpenStreetMap contributors';

  @override
  String get recenter => 'Recenter';

  @override
  String get debugTitle => 'Debug mode';

  @override
  String get debugEnabled => 'Debug mode enabled';

  @override
  String get debugTeleport => 'Tap the map to teleport';

  @override
  String get debugForceFind => 'Find';

  @override
  String get debugReset => 'Reset progress';

  @override
  String get debugSite => 'Active site';

  @override
  String get debugPhase => 'Game phase';

  @override
  String get debugPhaseAuto => 'Auto';

  @override
  String get debugPhasePlaying => 'Playing';

  @override
  String get debugPhaseEnded => 'Ended';

  @override
  String debugLastFix(String lat, String lng, String acc) {
    return 'Last fix: $lat, $lng (±$acc m)';
  }

  @override
  String outsideArea(String distance, String site) {
    return 'You\'re $distance away from $site. Head there to start exploring!';
  }

  @override
  String get waitingForGps => 'Waiting for GPS…';

  @override
  String get aboutDeveloper => 'Developed by BaldMan';

  @override
  String get anonymousPlayer => 'Mystery adventurer';

  @override
  String get licenses => 'Licenses';

  @override
  String get menuTooltip => 'Menu';

  @override
  String get resetConfirmBody =>
      'Erase all items and map progress for this site?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'OK';

  @override
  String get chooseAvatar => 'Choose avatar';

  @override
  String get avatarExplorerGirl => 'Explorer';

  @override
  String get avatarExplorerBoy => 'Adventurer';

  @override
  String get avatarMage => 'Mage';

  @override
  String get avatarKnight => 'Knight';

  @override
  String get avatarAlien => 'Alien';

  @override
  String get avatarRobot => 'Robot';

  @override
  String get avatarNinja => 'Ninja';

  @override
  String get avatarPirate => 'Pirate';

  @override
  String get avatarAstronaut => 'Astronaut';

  @override
  String get avatarSlime => 'Slime';

  @override
  String get locationLost =>
      'Location stopped. Make sure Location is on in your phone settings, then tap Start exploring.';

  @override
  String get debugPinTitle => 'Enter PIN';

  @override
  String get debugPinWrong => 'Wrong PIN';

  @override
  String get debugPinLocked => 'Too many tries. Try again in 10 minutes.';

  @override
  String get itemsFoundChannel => 'Items found';

  @override
  String get explorationChannel => 'Exploration';

  @override
  String foundDateTime(String date, String time) {
    return '$date at $time';
  }

  @override
  String get explorationInterrupted =>
      'Exploration stopped while the app was closed. Tap Start exploring to continue.';

  @override
  String get preciseLocationTitle => 'Precise location needed';

  @override
  String preciseLocationBody(String appName) {
    return '$appName needs precise location to find items. Allow \'Precise\' in settings.';
  }

  @override
  String gpsInaccurate(int meters) {
    return 'GPS signal too weak (±$meters m). Move outdoors.';
  }
}
