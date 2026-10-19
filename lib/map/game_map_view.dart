import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../game/geo.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/avatar.dart';
import '../models/geo_point.dart';
import '../models/tile_map.dart';
import 'fog_painter.dart';
import 'map_camera.dart';
import 'markers_painter.dart';
import 'sprite_sheets.dart';
import 'tile_map_painter.dart';

export 'fog_painter.dart' show FogQuery;
export 'markers_painter.dart' show Chest;

class GameMapView extends StatefulWidget {
  const GameMapView({
    super.key,
    required this.map,
    required this.projection,
    required this.sheets,
    required this.isRevealed,
    required this.player,
    required this.chests,
    this.siteCenter,
    this.onTapGeo,
    this.showLabels = true,
    this.avatar = Avatar.fallback,
  });
  final TileMap map;
  final LocalProjection projection;
  final SpriteSheets sheets;
  final FogQuery isRevealed;
  final GeoPoint? player;
  final List<Chest<GeoPoint>> chests; // closed ones show only where revealed
  final GeoPoint? siteCenter; // camera focus and pin while player is null
  final void Function(GeoPoint)? onTapGeo; // debug teleport
  final bool showLabels;
  final Avatar avatar;

  @override
  State<GameMapView> createState() => GameMapViewState();
}

class GameMapViewState extends State<GameMapView>
    with SingleTickerProviderStateMixin {
  late MapCamera _camera;
  late final AnimationController _bob;
  Size _viewport = Size.zero;
  bool _zoomedThisGesture = false;

  @visibleForTesting
  MapCamera get debugCamera => _camera;

  Offset _toCell(GeoPoint p) {
    final m = widget.projection.toMeters(p);
    return Offset(m.x / widget.map.cellMeters, m.y / widget.map.cellMeters);
  }

  // Found chests stay visible even under fog: the player has seen them.
  bool _visible(Chest<Offset> c) =>
      c.opened ||
      widget.isRevealed(
        (c.at.dx / fogCellTiles).floor(),
        (c.at.dy / fogCellTiles).floor(),
      );

  @override
  void initState() {
    super.initState();
    _camera = MapCamera(
      mapWidth: widget.map.width,
      mapHeight: widget.map.height,
    );
    final p = widget.player ?? widget.siteCenter;
    if (p != null) _camera.follow(_toCell(p));
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void didUpdateWidget(GameMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.map != widget.map) {
      _camera = MapCamera(
        mapWidth: widget.map.width,
        mapHeight: widget.map.height,
      );
    }
    final p = widget.player ?? widget.siteCenter;
    if (p != null) _camera.follow(_toCell(p));
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails d) => _zoomedThisGesture = false;

  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      if (d.focalPointDelta != Offset.zero) _camera.panBy(d.focalPointDelta);
      if (_zoomedThisGesture) return;
      if (d.scale > 1.25) {
        _camera.zoomIn();
        _zoomedThisGesture = true;
      } else if (d.scale < 0.8) {
        _camera.zoomOut();
        _zoomedThisGesture = true;
      }
    });
  }

  void _onTapUp(TapUpDetails d) {
    final cb = widget.onTapGeo;
    if (cb == null) return;
    final c = _camera.screenToCell(d.localPosition, _viewport);
    if (c.dx < 0 ||
        c.dy < 0 ||
        c.dx > widget.map.width ||
        c.dy > widget.map.height) {
      return; // off-map taps are ignored
    }
    final cm = widget.map.cellMeters;
    cb(widget.projection.fromMeters(c.dx * cm, c.dy * cm));
  }

  void _recenter() => setState(() {
    _camera.followPlayer = true;
    final p = widget.player ?? widget.siteCenter;
    if (p != null) _camera.follow(_toCell(p));
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final player = widget.player;
    final inset = MediaQuery.viewPaddingOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = constraints.biggest;
        return GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onTapUp: _onTapUp,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  painter: TileMapPainter(
                    map: widget.map,
                    camera: _camera,
                    sheets: widget.sheets,
                    showLabels: widget.showLabels,
                  ),
                ),
              ),
              RepaintBoundary(
                child: CustomPaint(
                  painter: FogPainter(
                    map: widget.map,
                    camera: _camera,
                    isRevealed: widget.isRevealed,
                  ),
                ),
              ),
              CustomPaint(
                painter: MarkersPainter(
                  camera: _camera,
                  sheets: widget.sheets,
                  player: player == null ? null : _toCell(player),
                  chests: [
                    for (final c in widget.chests)
                      (at: _toCell(c.at), opened: c.opened),
                  ].where(_visible).toList(),
                  pin: player == null && widget.siteCenter != null
                      ? _toCell(widget.siteCenter!)
                      : null,
                  bob: _bob,
                  avatar: widget.avatar,
                ),
              ),
              Positioned(
                left: inset.left,
                bottom: inset.bottom,
                child: _Attribution(l10n.osmAttribution),
              ),
              Positioned(
                right: inset.right + 8,
                bottom: inset.bottom + 8,
                child: _RecenterButton(
                  tooltip: l10n.recenter,
                  onPressed: _recenter,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.ink.withValues(alpha: 0.6),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'VT323',
        fontSize: 12,
        color: AppColors.paper,
      ),
    ),
  );
}

class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.tooltip, required this.onPressed});
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.ink,
    shape: const RoundedRectangleBorder(
      side: BorderSide(color: AppColors.paper, width: 3),
    ),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: const Icon(Icons.my_location, color: AppColors.paper),
    ),
  );
}
