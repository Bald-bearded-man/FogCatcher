import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @onboardingNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your name, adventurer?'**
  String get onboardingNameTitle;

  /// No description provided for @onboardingNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your first name'**
  String get onboardingNameHint;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'The map needs your location'**
  String get onboardingLocationTitle;

  /// No description provided for @onboardingLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Your location reveals the map and finds items. It never leaves your phone.'**
  String get onboardingLocationBody;

  /// No description provided for @onboardingLocationButton.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get onboardingLocationButton;

  /// No description provided for @onboardingLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Without your location you can\'t explore. Open settings to allow it.'**
  String get onboardingLocationDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @onboardingNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified of finds'**
  String get onboardingNotifTitle;

  /// No description provided for @onboardingNotifBody.
  ///
  /// In en, this message translates to:
  /// **'A notification tells you when you find an item, even with the screen off.'**
  String get onboardingNotifBody;

  /// No description provided for @onboardingNotifButton.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get onboardingNotifButton;

  /// No description provided for @onboardingBatteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep exploring in the background'**
  String get onboardingBatteryTitle;

  /// No description provided for @onboardingBatteryBody.
  ///
  /// In en, this message translates to:
  /// **'Choose \"Unrestricted\" for {appName} and don\'t close the app: leave it in the background.'**
  String onboardingBatteryBody(String appName);

  /// No description provided for @onboardingBatteryButton.
  ///
  /// In en, this message translates to:
  /// **'Open battery settings'**
  String get onboardingBatteryButton;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get onboardingStart;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @startExploring.
  ///
  /// In en, this message translates to:
  /// **'Start exploring'**
  String get startExploring;

  /// No description provided for @pauseExploring.
  ///
  /// In en, this message translates to:
  /// **'Stop exploring'**
  String get pauseExploring;

  /// No description provided for @stopExploringTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop exploring?'**
  String get stopExploringTitle;

  /// No description provided for @stopExploringBody.
  ///
  /// In en, this message translates to:
  /// **'Location tracking will stop. You won\'t find items or reveal the map until you tap Start exploring again.'**
  String get stopExploringBody;

  /// No description provided for @stopExploringConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopExploringConfirm;

  /// No description provided for @exploringNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'{appName} — exploring'**
  String exploringNotificationTitle(String appName);

  /// No description provided for @exploringNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the app open in the background to find items.'**
  String get exploringNotificationBody;

  /// No description provided for @itemFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Item found!'**
  String get itemFoundTitle;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'{found} / {total}'**
  String score(int found, int total);

  /// No description provided for @collectionTitle.
  ///
  /// In en, this message translates to:
  /// **'My loot'**
  String get collectionTitle;

  /// No description provided for @lockedItem.
  ///
  /// In en, this message translates to:
  /// **'???'**
  String get lockedItem;

  /// No description provided for @foundAt.
  ///
  /// In en, this message translates to:
  /// **'Found on {date}'**
  String foundAt(String date);

  /// No description provided for @shareScore.
  ///
  /// In en, this message translates to:
  /// **'Share my score'**
  String get shareScore;

  /// No description provided for @shareCaption.
  ///
  /// In en, this message translates to:
  /// **'I found {found} of {total} items in {appName} 🗺️'**
  String shareCaption(int found, int total, String appName);

  /// No description provided for @scoreCardItems.
  ///
  /// In en, this message translates to:
  /// **'{found} / {total} items'**
  String scoreCardItems(int found, int total);

  /// No description provided for @gameOverTitle.
  ///
  /// In en, this message translates to:
  /// **'The adventure is over!'**
  String get gameOverTitle;

  /// No description provided for @gameOverBody.
  ///
  /// In en, this message translates to:
  /// **'Thanks for playing. Share your score!'**
  String get gameOverBody;

  /// No description provided for @menuCollection.
  ///
  /// In en, this message translates to:
  /// **'My loot'**
  String get menuCollection;

  /// No description provided for @menuAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get menuAbout;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @osmAttribution.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get osmAttribution;

  /// No description provided for @recenter.
  ///
  /// In en, this message translates to:
  /// **'Recenter'**
  String get recenter;

  /// No description provided for @debugTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug mode'**
  String get debugTitle;

  /// No description provided for @debugEnabled.
  ///
  /// In en, this message translates to:
  /// **'Debug mode enabled'**
  String get debugEnabled;

  /// No description provided for @debugTeleport.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to teleport'**
  String get debugTeleport;

  /// No description provided for @debugForceFind.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get debugForceFind;

  /// No description provided for @debugReset.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get debugReset;

  /// No description provided for @debugSite.
  ///
  /// In en, this message translates to:
  /// **'Active site'**
  String get debugSite;

  /// No description provided for @debugPhase.
  ///
  /// In en, this message translates to:
  /// **'Game phase'**
  String get debugPhase;

  /// No description provided for @debugPhaseAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get debugPhaseAuto;

  /// No description provided for @debugPhasePlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get debugPhasePlaying;

  /// No description provided for @debugPhaseEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get debugPhaseEnded;

  /// No description provided for @debugLastFix.
  ///
  /// In en, this message translates to:
  /// **'Last fix: {lat}, {lng} (±{acc} m)'**
  String debugLastFix(String lat, String lng, String acc);

  /// No description provided for @outsideArea.
  ///
  /// In en, this message translates to:
  /// **'You\'re {distance} away from {site}. Head there to start exploring!'**
  String outsideArea(String distance, String site);

  /// No description provided for @waitingForGps.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS…'**
  String get waitingForGps;

  /// No description provided for @aboutDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developed by BaldMan'**
  String get aboutDeveloper;

  /// No description provided for @anonymousPlayer.
  ///
  /// In en, this message translates to:
  /// **'Mystery adventurer'**
  String get anonymousPlayer;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @menuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTooltip;

  /// No description provided for @resetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Erase all items and map progress for this site?'**
  String get resetConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirm;

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose avatar'**
  String get chooseAvatar;

  /// No description provided for @avatarExplorerGirl.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get avatarExplorerGirl;

  /// No description provided for @avatarExplorerBoy.
  ///
  /// In en, this message translates to:
  /// **'Adventurer'**
  String get avatarExplorerBoy;

  /// No description provided for @avatarMage.
  ///
  /// In en, this message translates to:
  /// **'Mage'**
  String get avatarMage;

  /// No description provided for @avatarKnight.
  ///
  /// In en, this message translates to:
  /// **'Knight'**
  String get avatarKnight;

  /// No description provided for @avatarAlien.
  ///
  /// In en, this message translates to:
  /// **'Alien'**
  String get avatarAlien;

  /// No description provided for @avatarRobot.
  ///
  /// In en, this message translates to:
  /// **'Robot'**
  String get avatarRobot;

  /// No description provided for @avatarNinja.
  ///
  /// In en, this message translates to:
  /// **'Ninja'**
  String get avatarNinja;

  /// No description provided for @avatarPirate.
  ///
  /// In en, this message translates to:
  /// **'Pirate'**
  String get avatarPirate;

  /// No description provided for @avatarAstronaut.
  ///
  /// In en, this message translates to:
  /// **'Astronaut'**
  String get avatarAstronaut;

  /// No description provided for @avatarSlime.
  ///
  /// In en, this message translates to:
  /// **'Slime'**
  String get avatarSlime;

  /// No description provided for @locationLost.
  ///
  /// In en, this message translates to:
  /// **'Location stopped. Make sure Location is on in your phone settings, then tap Start exploring.'**
  String get locationLost;

  /// No description provided for @debugPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get debugPinTitle;

  /// No description provided for @debugPinWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get debugPinWrong;

  /// No description provided for @debugPinLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Try again in 10 minutes.'**
  String get debugPinLocked;

  /// No description provided for @itemsFoundChannel.
  ///
  /// In en, this message translates to:
  /// **'Items found'**
  String get itemsFoundChannel;

  /// No description provided for @explorationChannel.
  ///
  /// In en, this message translates to:
  /// **'Exploration'**
  String get explorationChannel;

  /// No description provided for @foundDateTime.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String foundDateTime(String date, String time);

  /// No description provided for @explorationInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Exploration stopped while the app was closed. Tap Start exploring to continue.'**
  String get explorationInterrupted;

  /// No description provided for @preciseLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Precise location needed'**
  String get preciseLocationTitle;

  /// No description provided for @preciseLocationBody.
  ///
  /// In en, this message translates to:
  /// **'{appName} needs precise location to find items. Allow \'Precise\' in settings.'**
  String preciseLocationBody(String appName);

  /// No description provided for @gpsInaccurate.
  ///
  /// In en, this message translates to:
  /// **'GPS signal too weak (±{meters} m). Move outdoors.'**
  String gpsInaccurate(int meters);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
