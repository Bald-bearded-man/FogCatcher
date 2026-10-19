import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/item.dart';
import '../models/tileset_layout.dart';
import 'pixel_kit.dart';

const _spritesAsset = 'assets/tiles/sprites.png';
const _autoAdvance = Duration(seconds: 4);

Future<ui.Image?>? _spritesFuture;

/// Null when the sprite sheet is not bundled; callers fall back to icons.
Future<ui.Image?> _loadSprites() => _spritesFuture ??= () async {
  try {
    final data = await rootBundle.load(_spritesAsset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  } catch (_) {
    return null;
  }
}();

/// Full-screen chest-opening reveal, one card per queued item.
class RevealOverlay extends StatefulWidget {
  const RevealOverlay({super.key, required this.queue, required this.onDone});
  final List<Item> queue; // played in order; tap or 4 s auto-advance
  final VoidCallback onDone;

  @override
  State<RevealOverlay> createState() => _RevealOverlayState();
}

class _RevealOverlayState extends State<RevealOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );
  Timer? _timer;
  ui.Image? _sprites;
  int _index = 0;
  bool _buzzed = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onTick);
    _loadSprites().then((img) {
      if (mounted && img != null) setState(() => _sprites = img);
    });
    if (widget.queue.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      _startCard();
    }
  }

  void _startCard() {
    _buzzed = false;
    _c.forward(from: 0);
    _timer?.cancel();
    _timer = Timer(_autoAdvance, _next);
  }

  void _onTick() {
    if (!_buzzed && _c.value >= 0.4) {
      _buzzed = true;
      HapticFeedback.mediumImpact();
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    widget.onDone();
  }

  void _next() {
    if (_finished) return;
    if (_index + 1 >= widget.queue.length) {
      _finish();
    } else {
      setState(() => _index++);
      _startCard();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.queue.isEmpty) return const SizedBox.shrink();
    final item = widget.queue[_index];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _next,
      child: ColoredBox(
        color: AppColors.ink.withValues(alpha: 0.85),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => _content(context, item, _c.value),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Item item, double v) {
    final l10n = AppLocalizations.of(context);
    final cardT = Curves.easeOut.transform(((v - 0.5) / 0.5).clamp(0.0, 1.0));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 140, width: 140, child: _chest(v)),
        const SizedBox(height: 16),
        FadeTransition(
          opacity: AlwaysStoppedAnimation(cardT),
          child: SlideTransition(
            position: AlwaysStoppedAnimation(Offset(0, 0.3 * (1 - cardT))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PixelPanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.itemFoundTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: pixelTitleFont,
                        fontSize: 16,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: itemImage(item.image, label: item.title),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 26),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chest(double v) {
    final opened = v >= 0.4;
    final shake = v < 0.4 ? math.sin(v / 0.4 * math.pi * 6) * 0.08 : 0.0;
    final sparkles = v >= 0.5;
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: shake,
          child: _sprites == null
              ? Icon(
                  opened ? Icons.unarchive : Icons.inventory_2,
                  size: 96,
                  color: AppColors.accent,
                )
              : CustomPaint(
                  size: const Size(96, 96),
                  painter: _SpritePainter(
                    _sprites!,
                    opened ? spriteChestOpen : spriteChestClosed,
                  ),
                ),
        ),
        if (sparkles)
          for (var i = 0; i < spriteSparkleCount; i++) _sparkle(v, i),
      ],
    );
  }

  Widget _sparkle(double v, int i) {
    final a = (v - 0.5) / 0.5 * 2 * math.pi + i * math.pi / 2;
    final o = Offset(math.cos(a) * 56, math.sin(a) * 56);
    return Transform.translate(
      offset: o,
      child: _sprites == null
          ? const Icon(Icons.star, size: 16, color: AppColors.accent)
          : CustomPaint(
              size: const Size(32, 32),
              painter: _SpritePainter(_sprites!, spriteSparkleFirst + i),
            ),
    );
  }
}

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.image, this.frame);
  final ui.Image image;
  final int frame;

  @override
  void paint(Canvas canvas, Size size) {
    final ts = tileSize.toDouble();
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(frame * ts, 0, ts, ts),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(_SpritePainter old) =>
      old.image != image || old.frame != frame;
}

/// Item picture with a placeholder when the asset is missing.
Widget itemImage(String asset, {BoxFit fit = BoxFit.contain, String? label}) =>
    Image.asset(
      asset,
      semanticLabel: label,
      fit: fit,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.inventory_2, size: 48, color: AppColors.paper),
      ),
    );
