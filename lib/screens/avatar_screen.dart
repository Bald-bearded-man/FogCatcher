import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/avatar.dart';
import '../providers/providers.dart';
import '../widgets/avatar_sprite.dart';
import '../widgets/pixel_kit.dart';

String avatarLabel(AppLocalizations l10n, Avatar a) => switch (a) {
  Avatar.explorerGirl => l10n.avatarExplorerGirl,
  Avatar.explorerBoy => l10n.avatarExplorerBoy,
  Avatar.mage => l10n.avatarMage,
  Avatar.knight => l10n.avatarKnight,
  Avatar.alien => l10n.avatarAlien,
  Avatar.robot => l10n.avatarRobot,
  Avatar.ninja => l10n.avatarNinja,
  Avatar.pirate => l10n.avatarPirate,
  Avatar.astronaut => l10n.avatarAstronaut,
  Avatar.slime => l10n.avatarSlime,
};

/// Menu screen: picks and saves the avatar straight away.
class AvatarScreen extends ConsumerWidget {
  const AvatarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.chooseAvatar,
          style: const TextStyle(fontFamily: pixelTitleFont, fontSize: 14),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(child: AvatarPicker()),
        ),
      ),
    );
  }
}

/// Grid bound to the game state; shared by the menu screen and onboarding.
class AvatarPicker extends ConsumerWidget {
  const AvatarPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AvatarGrid(
    selected: ref.watch(gameControllerProvider.select((s) => s.avatar)),
    onSelected: ref.read(gameControllerProvider.notifier).setAvatar,
  );
}

class AvatarGrid extends StatefulWidget {
  const AvatarGrid({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final Avatar selected;
  final ValueChanged<Avatar> onSelected;

  @override
  State<AvatarGrid> createState() => _AvatarGridState();
}

class _AvatarGridState extends State<AvatarGrid>
    with SingleTickerProviderStateMixin {
  // Same 600 ms two-frame bob as the map marker.
  late final _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat();

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, _) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final a in Avatar.values)
            _AvatarTile(
              avatar: a,
              label: avatarLabel(l10n, a),
              bob: _bob.value >= 0.5 ? 1 : 0,
              selected: a == widget.selected,
              onTap: () => widget.onSelected(a),
            ),
        ],
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.avatar,
    required this.label,
    required this.bob,
    required this.selected,
    required this.onTap,
  });
  final Avatar avatar;
  final String label;
  final int bob;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      key: ValueKey('avatar-${avatar.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 88,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDeep : AppColors.ink,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.paper,
            width: selected ? 4 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarSprite(avatar: avatar, size: 64, bob: bob),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: pixelBodyFont, fontSize: 20),
            ),
          ],
        ),
      ),
    ),
  );
}
