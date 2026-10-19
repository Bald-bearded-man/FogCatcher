import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/interfaces.dart';
import '../widgets/pixel_kit.dart';

/// Approximate location fails every accuracy check, so ask for Precise.
/// Returns whether location is precise.
Future<bool> ensurePreciseLocation(
  BuildContext context,
  SystemSettings settings,
) async {
  if (await settings.hasPreciseLocation()) return true;
  if (!context.mounted) return false;
  final l10n = AppLocalizations.of(context);
  await showDialog<void>(
    context: context,
    builder: (ctx) => PixelDialog(
      title: l10n.preciseLocationTitle,
      body: l10n.preciseLocationBody(appTitle),
      actions: [
        PixelButton(
          label: l10n.cancel,
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        PixelButton(
          label: l10n.openSettings,
          onPressed: () {
            Navigator.of(ctx).pop();
            settings.openAppSettings();
          },
        ),
      ],
    ),
  );
  return false;
}
