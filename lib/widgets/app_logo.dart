import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import 'pixel_kit.dart';

enum AppLogoSize { large, compact }

const appLogoAsset = 'assets/brand/logo.png';

/// Pack logo plus the app title.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = AppLogoSize.large});
  final AppLogoSize size;

  @override
  Widget build(BuildContext context) {
    final large = size == AppLogoSize.large;
    final side = large ? 96.0 : 24.0;
    final image = Image.asset(
      appLogoAsset,
      width: side,
      height: side,
      filterQuality: FilterQuality.none, // pixel art
      semanticLabel: appTitle,
    );
    final title = Text(
      appTitle,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: pixelTitleFont,
        fontSize: large ? 22 : 10,
        color: AppColors.primary,
        shadows: const [Shadow(color: AppColors.ink, offset: Offset(2, 2))],
      ),
    );
    return large
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [image, const SizedBox(height: 12), title],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              image,
              const SizedBox(width: 8),
              Flexible(child: title),
            ],
          );
  }
}
