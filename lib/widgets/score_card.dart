import 'package:flutter/material.dart';

import '../config/pack.g.dart';
import '../l10n/generated/app_localizations.dart';
import '../map/sprite_sheets.dart';
import '../models/avatar.dart';
import 'avatar_sprite.dart';
import 'app_logo.dart';
import 'pixel_kit.dart';

const scoreCardAvatarSize = 64.0;
const scoreCardMaxThumbs = 12;

class ScoreCardData {
  const ScoreCardData({
    required this.playerName,
    required this.found,
    required this.total,
    required this.thumbnails,
    this.avatar = Avatar.fallback,
  });
  final String playerName;
  final Avatar avatar;
  final int found, total;
  final List<String> thumbnails; // asset paths, found order
}

/// Providers the card paints with; the renderer warms them into the image cache.
List<ImageProvider> scoreCardImageProviders(ScoreCardData data) => [
  const AssetImage(appLogoAsset), // AppLogo
  const AssetImage(avatarSheetAsset),
  _logoProvider,
  for (final t in data.thumbnails.take(scoreCardMaxThumbs)) AssetImage(t),
];

// Decoded at 32 px then upscaled unsmoothed for the pixelated look.
const _logoProvider = ResizeImage(AssetImage(appLogoAsset), width: 32);

/// 360x360 logical shareable card.
class ScoreCard extends StatelessWidget {
  const ScoreCard({super.key, required this.data});
  final ScoreCardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = data.playerName.trim().isEmpty
        ? l10n.anonymousPlayer
        : data.playerName.trim();
    final scoreText = l10n.score(data.found, data.total);
    final full = l10n.scoreCardItems(data.found, data.total);

    return SizedBox(
      width: 360,
      height: 360,
      child: ClipRect(
        child: DefaultTextStyle(
          // No Material ancestor when rendered off-screen; avoids debug underlines.
          style: const TextStyle(decoration: TextDecoration.none),
          child: ColoredBox(
            color: AppColors.ink,
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  bottom: -30,
                  width: 220,
                  height: 220,
                  child: const _LogoBackdrop(),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: AppLogo()),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AvatarSprite(
                            avatar: data.avatar,
                            size: scoreCardAvatarSize,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: pixelBodyFont,
                                fontSize: 32,
                                color: AppColors.paper,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _ScoreLine(scoreText: scoreText, full: full),
                      const SizedBox(height: 8),
                      Expanded(child: _ThumbRow(thumbnails: data.thumbnails)),
                      Text(
                        packEventLine,
                        style: const TextStyle(
                          fontFamily: pixelBodyFont,
                          fontSize: 18,
                          color: AppColors.paper,
                        ),
                      ),
                      Text(
                        l10n.aboutDeveloper,
                        style: TextStyle(
                          fontFamily: pixelBodyFont,
                          fontSize: 14,
                          color: AppColors.paper.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoBackdrop extends StatelessWidget {
  const _LogoBackdrop();

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: 0.2,
    child: Image(
      image: _logoProvider,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
  );
}

/// "5 / 12" in the title font, then the localized suffix (" items") in body font.
class _ScoreLine extends StatelessWidget {
  const _ScoreLine({required this.scoreText, required this.full});
  final String scoreText, full;

  @override
  Widget build(BuildContext context) {
    final suffix = full.startsWith(scoreText)
        ? full.substring(scoreText.length)
        : '';
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: suffix.isEmpty ? full : scoreText,
            style: const TextStyle(
              fontFamily: pixelTitleFont,
              fontSize: 28,
              color: AppColors.accent,
            ),
          ),
          if (suffix.isNotEmpty)
            TextSpan(
              text: suffix,
              style: const TextStyle(
                fontFamily: pixelBodyFont,
                fontSize: 24,
                color: AppColors.paper,
              ),
            ),
        ],
      ),
    );
  }
}

class _ThumbRow extends StatelessWidget {
  const _ThumbRow({required this.thumbnails});
  final List<String> thumbnails;

  @override
  Widget build(BuildContext context) {
    final shown = thumbnails.take(scoreCardMaxThumbs).toList();
    final extra = thumbnails.length - shown.length;
    return Align(
      alignment: Alignment.topLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 6 * 40 + 5 * 4,
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final t in shown) _Thumb(path: t),
              if (extra > 0) _MoreBadge(extra: extra),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('score-thumb'),
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: AppColors.ink,
      border: Border.all(color: AppColors.highlight, width: 2),
    ),
    child: Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.inventory_2, size: 22, color: AppColors.paper),
    ),
  );
}

class _MoreBadge extends StatelessWidget {
  const _MoreBadge({required this.extra});
  final int extra;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.highlight,
      border: Border.all(color: AppColors.paper, width: 2),
    ),
    child: Text(
      '+$extra',
      style: const TextStyle(
        fontFamily: pixelTitleFont,
        fontSize: 10,
        color: AppColors.paper,
      ),
    ),
  );
}
