import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/interfaces.dart';
import '../widgets/pixel_kit.dart';
import '../widgets/score_card.dart';
import '../widgets/score_card_renderer.dart';

class ScoreScreen extends StatefulWidget {
  const ScoreScreen({
    super.key,
    required this.data,
    required this.sharer,
    this.gameOver = false,
  });
  final ScoreCardData data;
  final ScoreSharer sharer;
  final bool gameOver;

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final data = widget.data;
    setState(() => _busy = true);
    try {
      final bytes = await renderScoreCard(data, locale: locale);
      await widget.sharer.sharePng(
        bytes,
        caption: l10n.shareCaption(data.found, data.total, appTitle),
      );
    } catch (_) {
      // No dedicated error string: reuse the share label with an error icon.
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.alert),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.shareScore)),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !widget.gameOver,
      child: Scaffold(
        appBar: widget.gameOver
            ? null
            : AppBar(
                title: Text(
                  l10n.collectionTitle,
                  style: const TextStyle(
                    fontFamily: pixelTitleFont,
                    fontSize: 14,
                  ),
                ),
              ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.gameOver) ...[
                    Text(
                      l10n.gameOverTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: pixelTitleFont,
                        fontSize: 16,
                        color: AppColors.primary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.gameOverBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ScoreCard(data: widget.data),
                  ),
                  const SizedBox(height: 24),
                  PixelButton(
                    label: l10n.shareScore,
                    busy: _busy,
                    onPressed: _busy ? null : _share,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
