import 'package:flutter/material.dart';

import '../map/sprite_sheets.dart';
import '../models/avatar.dart';

/// One frame of the avatar sheet, upscaled without smoothing.
class AvatarSprite extends StatelessWidget {
  const AvatarSprite({
    super.key,
    required this.avatar,
    this.size = 48,
    this.bob = 0,
  });
  final Avatar avatar;
  final double size;
  final int bob; // 0 idle, 1 bob

  @override
  Widget build(BuildContext context) {
    final count = Avatar.frameCount;
    final frame = avatar.frame(bob);
    // Shows the whole strip at frame scale and slides the wanted frame into view.
    return SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: OverflowBox(
          minWidth: size * count,
          maxWidth: size * count,
          alignment: Alignment(2 * frame / (count - 1) - 1, 0),
          child: Image.asset(
            avatarSheetAsset,
            width: size * count,
            height: size,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) => SizedBox(width: size * count),
          ),
        ),
      ),
    );
  }
}
