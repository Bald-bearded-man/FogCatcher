import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../game/fix_filter.dart';
import '../game/geo.dart';
import '../l10n/generated/app_localizations.dart';
import '../map/game_map_view.dart';
import '../models/avatar.dart';
import '../models/item.dart';
import '../models/site.dart';
import '../providers/game_controller.dart';
import '../providers/providers.dart';
import '../services/content_repository.dart';
import '../widgets/avatar_sprite.dart';
import '../widgets/app_logo.dart';
import '../widgets/pixel_kit.dart';
import '../widgets/reveal_overlay.dart';
import '../widgets/score_card.dart';
import '../widgets/score_card_renderer.dart';
import 'about_screen.dart';
import 'avatar_screen.dart';
import 'collection_screen.dart';
import 'debug_screen.dart';
import 'precise_location_dialog.dart';

/// Score card of the active site, thumbnails in found order.
ScoreCardData scoreDataOf(GameState s, List<SiteBundle> content) {
  final items = s.bundleOf(content).items;
  final found = items.where((i) => s.found.containsKey(i.id)).toList()
    ..sort((a, b) => s.found[a.id]!.compareTo(s.found[b.id]!));
  return ScoreCardData(
    playerName: s.playerName ?? '',
    avatar: s.avatar,
    found: found.length,
    total: items.length,
    thumbnails: [for (final i in found) i.image],
  );
}

/// Renders the score card and hands it to the share sheet.
Future<void> shareScore(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context);
  final messenger = ScaffoldMessenger.of(context);
  final data = scoreDataOf(
    ref.read(gameControllerProvider),
    ref.read(contentProvider),
  );
  try {
    final png = await renderScoreCard(data, locale: locale);
    await ref
        .read(sharerProvider)
        .sharePng(
          png,
          caption: l10n.shareCaption(data.found, data.total, appTitle),
        );
  } catch (_) {
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
  }
}

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Rebuild so the reveal waits until the app is back in front.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) => setState(() {});

  Future<bool> _confirmStop() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => PixelDialog(
        title: l10n.stopExploringTitle,
        body: l10n.stopExploringBody,
        actions: [
          PixelButton(
            label: l10n.cancel,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          PixelButton(
            label: l10n.stopExploringConfirm,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _toggleExploring() async {
    final controller = ref.read(gameControllerProvider.notifier);
    if (ref.read(gameControllerProvider).exploring && !(await _confirmStop())) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      if (ref.read(gameControllerProvider).exploring) {
        await controller.pauseExploring();
      } else if (await _ensureLocation()) {
        // Onboarding may have been left before its notifications step.
        // Android shows nothing when it is already granted.
        await ref.read(systemSettingsProvider).requestNotificationPermission();
        await controller.startExploring();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Permission may have been revoked since onboarding.
  Future<bool> _ensureLocation() async {
    final settings = ref.read(systemSettingsProvider);
    if (await settings.requestLocationPermission()) {
      if (!mounted) return false;
      return ensurePreciseLocation(context, settings);
    }
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => PixelDialog(
        title: l10n.onboardingLocationTitle,
        body: l10n.onboardingLocationDenied,
        actions: [
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

  void _push(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  void _openCollection() => _push(
    Consumer(
      builder: (context, ref, _) {
        final s = ref.watch(gameControllerProvider);
        return CollectionScreen(
          items: s.bundleOf(ref.watch(contentProvider)).items,
          found: s.found,
          onShare: () => shareScore(context, ref),
        );
      },
    ),
  );

  Future<void> _openMenu() async {
    final l10n = AppLocalizations.of(context);
    final s = ref.read(gameControllerProvider);
    final entries = <(String, VoidCallback)>[
      (l10n.menuCollection, _openCollection),
      (l10n.shareScore, () => shareScore(context, ref)),
      (
        s.exploring ? l10n.pauseExploring : l10n.startExploring,
        _toggleExploring,
      ),
      (l10n.chooseAvatar, () => _push(const AvatarScreen())),
      (l10n.menuAbout, () => _push(const AboutScreen())),
      if (s.debug) (l10n.debugTitle, () => _push(const DebugScreen())),
    ];
    final picked = await showModalBottomSheet<VoidCallback>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: PixelPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (label, action) in entries) ...[
                  PixelButton(
                    label: label,
                    onPressed: () => Navigator.of(ctx).pop(action),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted) picked?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(gameControllerProvider);
    final bundle = s.bundleOf(ref.watch(contentProvider));
    final items = bundle.items;
    final foundCount = items.where((i) => s.found.containsKey(i.id)).length;
    final showReveal =
        s.unseen.isNotEmpty &&
        isAppInForeground() &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _map(s, bundle),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _Hud(
                    avatar: s.avatar,
                    name: s.playerName ?? l10n.anonymousPlayer,
                    score: l10n.score(foundCount, items.length),
                    onMenu: _openMenu,
                  ),
                  if (_status(s, bundle.site, l10n) case final text?)
                    _StatusBanner(text),
                  const Spacer(),
                  PixelButton(
                    label: s.exploring
                        ? l10n.pauseExploring
                        : l10n.startExploring,
                    busy: _busy,
                    onPressed: _busy ? null : _toggleExploring,
                  ),
                  // Keeps the button clear of the map's recenter control.
                  const SizedBox(height: 56),
                ],
              ),
            ),
          ),
          if (showReveal) _reveal(s.unseen, items),
        ],
      ),
    );
  }

  // Why the map is not moving: lost location, no fix yet, weak fix or outside the area.
  String? _status(GameState s, Site site, AppLocalizations l10n) {
    if (s.locationLost) return l10n.locationLost;
    if (s.interrupted) return l10n.explorationInterrupted;
    final fix = s.lastFix;
    if (fix == null) return s.exploring ? l10n.waitingForGps : null;
    return switch (filterFix(fix, site)) {
      FixVerdict.accepted => null,
      FixVerdict.inaccurate => l10n.gpsInaccurate(fix.accuracyMeters.round()),
      FixVerdict.outsideSite => l10n.outsideArea(
        formatDistance(haversineMeters(fix.point, site.center)),
        site.name,
      ),
    };
  }

  Widget _map(GameState s, SiteBundle bundle) {
    final sheets = ref.watch(spriteSheetsProvider).valueOrNull;
    if (sheets == null) {
      return const ColoredBox(color: AppColors.primaryDeep);
    }
    final fix = s.lastFix;
    final accepted =
        fix != null && filterFix(fix, bundle.site) == FixVerdict.accepted;
    final controller = ref.read(gameControllerProvider.notifier);
    return GameMapView(
      key: ValueKey(s.siteId),
      map: bundle.map,
      projection: siteProjection(bundle),
      sheets: sheets,
      isRevealed: s.fog.isRevealed,
      player: accepted ? fix.point : null,
      siteCenter: bundle.site.center,
      chests: [
        for (final i in bundle.items)
          (at: i.position, opened: s.found.containsKey(i.id)),
      ],
      onTapGeo: s.debug ? controller.teleport : null,
      avatar: s.avatar,
    );
  }

  Widget _reveal(List<String> unseen, List<Item> items) {
    final byId = {for (final i in items) i.id: i};
    final ids = List<String>.of(unseen);
    return RevealOverlay(
      queue: [for (final id in ids) ?byId[id]],
      onDone: () => ref.read(gameControllerProvider.notifier).markSeen(ids),
    );
  }
}

/// Logo on top; avatar, name, score and menu below.
class _Hud extends StatelessWidget {
  const _Hud({
    required this.avatar,
    required this.name,
    required this.score,
    required this.onMenu,
  });
  final Avatar avatar;
  final String name;
  final String score;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) => PixelPanel(
    padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogo(size: AppLogoSize.compact),
        Row(
          children: [
            AvatarSprite(avatar: avatar, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            PixelPanel(
              fill: AppColors.shade,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                score,
                style: const TextStyle(
                  fontFamily: pixelTitleFont,
                  fontSize: 10,
                ),
              ),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context).menuTooltip,
              onPressed: onMenu,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(Icons.menu, color: AppColors.paper),
            ),
          ],
        ),
      ],
    ),
  );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: PixelPanel(
      borderColor: AppColors.accent,
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22),
      ),
    ),
  );
}
