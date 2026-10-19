import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../game/fix_filter.dart';
import '../game/fog_grid.dart';
import '../game/game_phase.dart';
import '../game/geo.dart';
import '../game/item_detector.dart';
import '../game/site_selector.dart';
import '../models/avatar.dart';
import '../models/geo_point.dart';
import '../models/item.dart';
import '../models/position_fix.dart';
import '../services/content_repository.dart';
import '../services/interfaces.dart';
import '../services/progress_repository.dart';
import '../services/simulated_position_source.dart';

/// Projection shared by fog, markers and the map of one site.
LocalProjection siteProjection(SiteBundle b) =>
    LocalProjection(origin: b.map.origin, refLat: b.site.center.lat);

class GameState {
  const GameState({
    required this.siteId,
    required this.found,
    required this.fog,
    required this.unseen,
    required this.exploring,
    required this.phase,
    required this.phaseOverride,
    required this.debug,
    required this.playerName,
    this.avatar = Avatar.fallback,
    this.locationLost = false,
    this.interrupted = false,
    this.lastFix,
    this.fogVersion = 0,
  });
  final String siteId;
  final Map<String, DateTime> found;
  final FogGrid fog;
  final List<String> unseen;
  final bool exploring;
  final GamePhase phase;
  final PhaseOverride phaseOverride;
  final bool debug;
  final String? playerName;
  final Avatar avatar;
  final bool locationLost; // the source stopped itself while exploring
  final bool interrupted; // the process died while exploring
  final PositionFix? lastFix;
  final int fogVersion; // bumps on reveal so painters repaint

  SiteBundle bundleOf(List<SiteBundle> all) =>
      all.firstWhere((b) => b.site.id == siteId);

  GameState copyWith({
    String? siteId,
    Map<String, DateTime>? found,
    FogGrid? fog,
    List<String>? unseen,
    bool? exploring,
    GamePhase? phase,
    PhaseOverride? phaseOverride,
    bool? debug,
    String? playerName,
    Avatar? avatar,
    bool? locationLost,
    bool? interrupted,
    PositionFix? lastFix,
    int? fogVersion,
  }) => GameState(
    siteId: siteId ?? this.siteId,
    found: found ?? this.found,
    fog: fog ?? this.fog,
    unseen: unseen ?? this.unseen,
    exploring: exploring ?? this.exploring,
    phase: phase ?? this.phase,
    phaseOverride: phaseOverride ?? this.phaseOverride,
    debug: debug ?? this.debug,
    playerName: playerName ?? this.playerName,
    avatar: avatar ?? this.avatar,
    locationLost: locationLost ?? this.locationLost,
    interrupted: interrupted ?? this.interrupted,
    lastFix: lastFix ?? this.lastFix,
    fogVersion: fogVersion ?? this.fogVersion,
  );
}

typedef _Progress = ({
  Map<String, DateTime> found,
  FogGrid fog,
  List<String> unseen,
});

class GameController extends StateNotifier<GameState> {
  GameController({
    required ProgressRepository repo,
    required List<SiteBundle> sites,
    required SwitchablePositionSource source,
    required ItemFoundNotifier notifier,
    required bool Function() isForeground,
    Random? random,
  }) : _repo = repo,
       _sites = sites,
       _source = source,
       _notifier = notifier,
       _isForeground = isForeground,
       super(_initialState(repo, sites, source, random ?? Random())) {
    if (state.phase == GamePhase.ended) _end();
    _subs
      // The source reports a self-stop (location off) as a stream error.
      ..add(source.fixes.listen(onFix, onError: (Object _) => syncExploring()))
      ..add(notifier.taps.listen(_bringToFront));
    final launchId = notifier.takeLaunchItemId();
    if (launchId != null) _bringToFront(launchId);
    _timers
      ..add(
        Timer.periodic(const Duration(minutes: 1), (_) {
          refreshPhase();
          syncExploring();
        }),
      )
      ..add(Timer.periodic(const Duration(seconds: 10), (_) => _flushFog()));
  }

  final ProgressRepository _repo;
  final List<SiteBundle> _sites;
  final SwitchablePositionSource _source;
  final ItemFoundNotifier _notifier;
  final bool Function() _isForeground;
  final _subs = <StreamSubscription<Object>>[];
  final _timers = <Timer>[];
  bool _fogDirty = false;

  static GameState _initialState(
    ProgressRepository repo,
    List<SiteBundle> sites,
    SwitchablePositionSource source,
    Random random,
  ) {
    final siteId = _resolveSite(null, sites, repo.activeSiteId);
    final p = _loadProgress(repo, _find(sites, siteId));
    return GameState(
      siteId: siteId,
      found: p.found,
      fog: p.fog,
      unseen: p.unseen,
      // The flag is not trusted on reopen: the player taps start again.
      exploring: source.isRunning,
      // Play policy needs a user tap to restart, so only say it stopped.
      interrupted: repo.exploring && !source.isRunning,
      phase: gamePhase(clock.now().toUtc()),
      phaseOverride: PhaseOverride.auto,
      debug: repo.debugEnabled,
      playerName: repo.playerName,
      avatar: _initialAvatar(repo, random),
    );
  }

  /// First opening gets a random avatar, saved so onboarding shows it picked.
  static Avatar _initialAvatar(ProgressRepository repo, Random random) {
    if (repo.hasAvatar) return repo.avatar;
    final a = Avatar.values[random.nextInt(Avatar.values.length)];
    unawaited(repo.setAvatar(a));
    return a;
  }

  static SiteBundle _find(List<SiteBundle> sites, String id) =>
      sites.firstWhere((b) => b.site.id == id);

  // selectSite falls back to defaultSiteId, which a test or trimmed bundle may lack.
  static String _resolveSite(
    GeoPoint? p,
    List<SiteBundle> sites,
    String? lastId,
  ) {
    final id = selectSite(p, [for (final b in sites) b.site], lastId);
    return sites.any((b) => b.site.id == id) ? id : sites.first.site.id;
  }

  static _Progress _loadProgress(ProgressRepository repo, SiteBundle b) {
    final p = repo.load(b.site.id);
    final empty = FogGrid.forTileMap(b.map);
    final bytes = p.fogBytes;
    return (
      found: Map<String, DateTime>.unmodifiable(p.found),
      fog: bytes == null
          ? empty
          : FogGrid.fromBytes(empty.width, empty.height, bytes),
      unseen: List<String>.unmodifiable(p.unseen),
    );
  }

  Future<void> setPlayerName(String name) async {
    await _repo.setPlayerName(name);
    if (mounted) state = state.copyWith(playerName: name);
  }

  Future<void> setAvatar(Avatar a) async {
    await _repo.setAvatar(a);
    if (mounted) state = state.copyWith(avatar: a);
  }

  Future<void> startExploring() async {
    if (state.phase == GamePhase.ended) return;
    await _source.start();
    await _repo.setExploring(true);
    if (!mounted) return;
    state = state.copyWith(
      exploring: true,
      locationLost: false,
      interrupted: false,
    );
    syncExploring(); // it may have failed already
  }

  Future<void> pauseExploring() async {
    _flushFog();
    await _source.stop();
    await _repo.setExploring(false);
    if (mounted) state = state.copyWith(exploring: false, locationLost: false);
  }

  /// Catches up when the source stopped on its own, e.g. location switched off.
  void syncExploring() {
    if (!mounted || !state.exploring || _source.isRunning) return;
    unawaited(_repo.setExploring(false));
    state = state.copyWith(exploring: false, locationLost: true);
  }

  void onFix(PositionFix fix) {
    refreshPhase(); // the minute timer can lag the deadline by up to 60 s
    if (state.phase == GamePhase.ended) return;
    final usable = fix.accuracyMeters <= maxDisplayAccuracyMeters;
    final siteId = _resolveSite(
      usable ? fix.point : null,
      _sites,
      state.siteId,
    );
    if (siteId != state.siteId) _switchSite(siteId);
    final bundle = state.bundleOf(_sites);
    if (filterFix(fix, bundle.site) != FixVerdict.accepted) {
      state = state.copyWith(lastFix: fix);
      return;
    }
    final revealed = _reveal(fix.point, bundle);
    state = state.copyWith(
      lastFix: fix,
      fogVersion: revealed ? state.fogVersion + 1 : null,
    );
    if (fix.accuracyMeters > maxFixAccuracyMeters) return; // items need 30 m
    final hits = detectItems(fix.point, bundle.items, state.found.keys.toSet());
    if (hits.isNotEmpty) {
      unawaited(_recordFinds(hits, notify: !_isForeground()));
    }
  }

  Future<void> markSeen(List<String> ids) async {
    final unseen = List<String>.unmodifiable(
      state.unseen.where((id) => !ids.contains(id)),
    );
    state = state.copyWith(unseen: unseen);
    await _repo.saveUnseen(state.siteId, unseen);
  }

  void refreshPhase() {
    final phase = gamePhase(clock.now().toUtc(), override: state.phaseOverride);
    if (phase == state.phase) return;
    state = state.copyWith(phase: phase);
    if (phase == GamePhase.ended) _end();
  }

  Future<void> setDebug(bool v) async {
    await _repo.setDebugEnabled(v);
    if (!mounted) return;
    if (v) {
      state = state.copyWith(debug: true);
      return;
    }
    _source.useSimulated = false;
    state = state.copyWith(debug: false, phaseOverride: PhaseOverride.auto);
    refreshPhase();
  }

  /// Feeds [p] through the simulated source so it takes the same path as GPS.
  void teleport(GeoPoint p) {
    if (!state.debug) return;
    _source.useSimulated = true;
    final sim = _source.simulated;
    if (sim is SimulatedPositionSource) {
      // Pause stops the simulated source too, so restart it before emitting.
      unawaited(sim.start().then((_) => sim.emit(p)));
    }
  }

  Future<void> forceFind(String itemId) async {
    if (!state.debug || state.found.containsKey(itemId)) return;
    final item = state
        .bundleOf(_sites)
        .items
        .where((i) => i.id == itemId)
        .firstOrNull;
    if (item != null) await _recordFinds([item], notify: false);
  }

  Future<void> resetProgress() async {
    final siteId = state.siteId;
    _fogDirty = false;
    await _repo.reset(siteId);
    if (!mounted || state.siteId != siteId) return;
    state = state.copyWith(
      found: const {},
      unseen: const [],
      fog: FogGrid.forTileMap(state.bundleOf(_sites).map),
      fogVersion: state.fogVersion + 1,
    );
  }

  Future<void> forceSite(String id) async {
    if (!state.debug || id == state.siteId) return;
    if (!_sites.any((b) => b.site.id == id)) return;
    _switchSite(id);
  }

  void setPhaseOverride(PhaseOverride o) {
    if (!state.debug) return;
    state = state.copyWith(phaseOverride: o);
    refreshPhase();
  }

  // FogGrid.reveal throws on an empty grid.
  bool _reveal(GeoPoint p, SiteBundle b) {
    final fog = state.fog;
    if (fog.width == 0 || fog.height == 0) return false;
    final changed = fog.reveal(
      p,
      siteProjection(b),
      tileCellMeters * fogCellTiles,
      fogRevealMeters,
    );
    _fogDirty |= changed;
    return changed;
  }

  /// State is updated before the first await so a quick next fix cannot find them twice.
  Future<void> _recordFinds(List<Item> items, {required bool notify}) async {
    final siteId = state.siteId;
    final now = clock.now().toUtc();
    final ids = [for (final i in items) i.id];
    final found = {...state.found, for (final id in ids) id: now};
    final unseen = [...state.unseen.where((id) => !ids.contains(id)), ...ids];
    state = state.copyWith(
      found: Map.unmodifiable(found),
      unseen: List.unmodifiable(unseen),
    );
    await _repo.saveFound(siteId, found);
    await _repo.saveUnseen(siteId, unseen);
    if (!notify) return;
    for (final i in items) {
      try {
        await _notifier.showItemFound(i);
      } catch (e) {
        debugPrint('Item notification failed: $e');
      }
    }
  }

  void _bringToFront(String id) {
    if (!state.found.containsKey(id)) return;
    final unseen = List<String>.unmodifiable([
      id,
      ...state.unseen.where((u) => u != id),
    ]);
    state = state.copyWith(unseen: unseen);
    unawaited(_repo.saveUnseen(state.siteId, unseen));
  }

  void _switchSite(String id) {
    _flushFog();
    final p = _loadProgress(_repo, _find(_sites, id));
    state = state.copyWith(
      siteId: id,
      found: p.found,
      fog: p.fog,
      unseen: p.unseen,
      fogVersion: state.fogVersion + 1,
    );
    unawaited(_repo.setActiveSiteId(id));
  }

  void _end() {
    _flushFog();
    unawaited(_source.stop());
    unawaited(_repo.setExploring(false));
    state = state.copyWith(exploring: false);
  }

  void _flushFog() {
    if (!_fogDirty) return;
    _fogDirty = false;
    unawaited(_repo.saveFog(state.siteId, state.fog.toBytes()));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    for (final t in _timers) {
      t.cancel();
    }
    _flushFog();
    super.dispose();
  }
}
