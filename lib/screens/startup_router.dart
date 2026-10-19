import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_phase.dart';
import '../providers/providers.dart';
import 'map_screen.dart';
import 'onboarding_screen.dart';
import 'score_screen.dart';

/// Ended → score only; no name at launch → onboarding; else the map.
class StartupRouter extends ConsumerStatefulWidget {
  const StartupRouter({super.key});

  @override
  ConsumerState<StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends ConsumerState<StartupRouter>
    with WidgetsBindingObserver {
  // Decided once: onboarding saves the name on its first step but runs to the end.
  late bool _onboarding = ref.read(gameControllerProvider).playerName == null;

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      ref.read(gameControllerProvider.notifier)
        ..refreshPhase()
        ..syncExploring();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pushed screens (collection, debug, menus) must not outlive the game.
    ref.listen(gameControllerProvider.select((s) => s.phase), (_, phase) {
      if (phase == GamePhase.ended) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    });
    final state = ref.watch(gameControllerProvider);
    if (state.phase == GamePhase.ended) {
      return ScoreScreen(
        gameOver: true,
        data: scoreDataOf(state, ref.watch(contentProvider)),
        sharer: ref.watch(sharerProvider),
      );
    }
    if (_onboarding) {
      return OnboardingScreen(
        onDone: () => setState(() => _onboarding = false),
      );
    }
    return const MapScreen();
  }
}
