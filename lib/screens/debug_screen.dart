import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../game/game_phase.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/providers.dart';
import '../widgets/pixel_kit.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  Future<void> _confirmReset() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => PixelDialog(
        title: l10n.debugReset,
        body: l10n.resetConfirmBody,
        actions: [
          PixelButton(
            label: l10n.cancel,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          PixelButton(
            label: l10n.confirm,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(gameControllerProvider.notifier).resetProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final content = ref.watch(contentProvider);
    final source = ref.watch(positionSourceProvider);
    final bundle = s.bundleOf(content);
    final fix = s.lastFix;
    const label = TextStyle(fontFamily: pixelTitleFont, fontSize: 10);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.debugTitle, style: label)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              fix == null
                  ? '—'
                  : l10n.debugLastFix(
                      fix.point.lat.toStringAsFixed(6),
                      fix.point.lng.toStringAsFixed(6),
                      fix.accuracyMeters.toStringAsFixed(0),
                    ),
            ),
            SwitchListTile(
              title: Text(l10n.debugTeleport),
              value: source.useSimulated,
              onChanged: (v) => setState(() => source.useSimulated = v),
            ),
            const SizedBox(height: 12),
            Text(l10n.debugSite, style: label),
            DropdownButton<String>(
              value: s.siteId,
              isExpanded: true,
              items: [
                for (final b in content)
                  DropdownMenuItem(value: b.site.id, child: Text(b.site.name)),
              ],
              onChanged: (id) => id == null ? null : controller.forceSite(id),
            ),
            const SizedBox(height: 12),
            Text(l10n.debugPhase, style: label),
            const SizedBox(height: 8),
            SegmentedButton<PhaseOverride>(
              segments: [
                ButtonSegment(
                  value: PhaseOverride.auto,
                  label: Text(l10n.debugPhaseAuto),
                ),
                ButtonSegment(
                  value: PhaseOverride.playing,
                  label: Text(l10n.debugPhasePlaying),
                ),
                ButtonSegment(
                  value: PhaseOverride.ended,
                  label: Text(l10n.debugPhaseEnded),
                ),
              ],
              selected: {s.phaseOverride},
              onSelectionChanged: (v) => controller.setPhaseOverride(v.single),
            ),
            const SizedBox(height: 12),
            for (final item in bundle.items)
              ListTile(
                title: Text(item.title),
                trailing: s.found.containsKey(item.id)
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : TextButton(
                        onPressed: () => controller.forceFind(item.id),
                        child: Text(l10n.debugForceFind),
                      ),
              ),
            const SizedBox(height: 12),
            PixelButton(label: l10n.debugReset, onPressed: _confirmReset),
          ],
        ),
      ),
    );
  }
}
