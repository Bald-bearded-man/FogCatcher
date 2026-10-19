import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/providers.dart';
import '../widgets/app_logo.dart';
import '../widgets/pixel_kit.dart';
import 'avatar_screen.dart';
import 'precise_location_dialog.dart';

const maxNameLength = 24;

/// Name → avatar → location → notifications → battery, then [onDone].
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  final _name = TextEditingController();
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  void _next() => _pages.jumpToPage((_pages.page ?? 0).round() + 1);

  Future<void> _saveName() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(gameControllerProvider.notifier)
        .setPlayerName(_name.text.trim());
    if (mounted) _next();
  }

  Future<void> _askLocation() async {
    final settings = ref.read(systemSettingsProvider);
    final ok = await settings.requestLocationPermission();
    if (!mounted) return;
    setState(() => _locationDenied = !ok);
    if (!ok) return;
    // Explained once here; the Start button asks again until it is fixed.
    await ensurePreciseLocation(context, settings);
    if (mounted) _next();
  }

  Future<void> _askNotifications() async {
    await ref.read(systemSettingsProvider).requestNotificationPermission();
    if (mounted) _next();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.read(systemSettingsProvider);
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pages,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _Step(
              logo: AppLogoSize.large,
              title: l10n.onboardingNameTitle,
              body: TextField(
                controller: _name,
                maxLength: maxNameLength,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 24),
                decoration: InputDecoration(
                  hintText: l10n.onboardingNameHint,
                  counterText: '',
                ),
              ),
              buttons: [
                PixelButton(
                  label: l10n.onboardingContinue,
                  onPressed: _name.text.trim().isEmpty ? null : _saveName,
                ),
              ],
            ),
            _Step(
              title: l10n.chooseAvatar,
              body: const AvatarPicker(),
              buttons: [
                PixelButton(label: l10n.onboardingContinue, onPressed: _next),
              ],
            ),
            _Step(
              title: l10n.onboardingLocationTitle,
              body: Text(
                _locationDenied
                    ? l10n.onboardingLocationDenied
                    : l10n.onboardingLocationBody,
                style: TextStyle(
                  color: _locationDenied ? AppColors.alert : null,
                ),
              ),
              buttons: [
                PixelButton(
                  label: l10n.onboardingLocationButton,
                  onPressed: _askLocation,
                ),
                if (_locationDenied)
                  PixelButton(
                    label: l10n.openSettings,
                    onPressed: settings.openAppSettings,
                  ),
              ],
            ),
            _Step(
              title: l10n.onboardingNotifTitle,
              body: Text(l10n.onboardingNotifBody),
              buttons: [
                PixelButton(
                  label: l10n.onboardingNotifButton,
                  onPressed: _askNotifications,
                ),
                PixelButton(label: l10n.skip, onPressed: _next),
              ],
            ),
            _Step(
              title: l10n.onboardingBatteryTitle,
              body: Text(l10n.onboardingBatteryBody(appTitle)),
              buttons: [
                PixelButton(
                  label: l10n.onboardingBatteryButton,
                  onPressed: settings.openBatteryOptimizationSettings,
                ),
                PixelButton(
                  label: l10n.onboardingStart,
                  onPressed: widget.onDone,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.title,
    required this.body,
    required this.buttons,
    this.logo = AppLogoSize.compact,
  });
  final AppLogoSize logo;
  final String title;
  final Widget body;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLogo(size: logo),
          const SizedBox(height: 16),
          PixelPanel(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: pixelTitleFont,
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                DefaultTextStyle.merge(
                  style: const TextStyle(
                    fontFamily: pixelBodyFont,
                    fontSize: 24,
                  ),
                  child: body,
                ),
                for (final b in buttons) ...[const SizedBox(height: 12), b],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
