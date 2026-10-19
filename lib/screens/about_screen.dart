import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../game/debug_pin.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/providers.dart';
import '../widgets/app_logo.dart';
import '../widgets/pixel_kit.dart';

// Set by the build with --dart-define; package_info_plus is not a dependency.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');
const debugTapCount = 7;

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  int _taps = 0;

  Future<void> _onVersionTap() async {
    if (++_taps < debugTapCount) return;
    _taps = 0;
    final gate = ref.read(debugPinGateProvider);
    if (!gate.enabled) return; // built without a PIN hash
    final messenger = ScaffoldMessenger.of(context);
    final text = AppLocalizations.of(context).debugEnabled;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _PinDialog(gate: gate),
    );
    if (ok != true || !mounted) return;
    await ref.read(gameControllerProvider.notifier).setDebug(true);
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.menuAbout,
          style: const TextStyle(fontFamily: pixelTitleFont, fontSize: 14),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Center(child: AppLogo()),
            const SizedBox(height: 16),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onVersionTap,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  l10n.aboutVersion(appVersion),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Text(l10n.aboutDeveloper, textAlign: TextAlign.center),
            Text(l10n.osmAttribution, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            PixelButton(
              label: l10n.licenses,
              onPressed: () => showLicensePage(
                context: context,
                applicationName: appTitle,
                applicationVersion: appVersion,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.gate});
  final DebugPinGate gate;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _pin = TextEditingController();
  late bool _locked = widget.gate.locked;
  bool _wrong = false;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _submit() {
    final result = widget.gate.check(_pin.text);
    if (result == PinResult.ok) {
      Navigator.of(context).pop(true);
      return;
    }
    _pin.clear();
    setState(() {
      _locked = result == PinResult.locked;
      _wrong = result == PinResult.wrong;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _locked
        ? l10n.debugPinLocked
        : _wrong
        ? l10n.debugPinWrong
        : null;
    return PixelDialog(
      title: l10n.debugPinTitle,
      body: '',
      content: TextField(
        controller: _pin,
        enabled: !_locked,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 24),
        decoration: InputDecoration(
          errorText: error,
          errorStyle: const TextStyle(color: AppColors.alert),
        ),
        onSubmitted: _locked ? null : (_) => _submit(),
      ),
      actions: [
        PixelButton(
          label: l10n.cancel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PixelButton(label: l10n.confirm, onPressed: _locked ? null : _submit),
      ],
    );
  }
}
