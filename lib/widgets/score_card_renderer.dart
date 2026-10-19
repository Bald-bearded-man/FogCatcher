import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../config/theme.dart';
import '../l10n/generated/app_localizations.dart';
import 'score_card.dart';

const _cardSize = Size(360, 360);

/// Resolves [p] into the image cache so the off-screen build paints it at once.
Future<void> _warm(ImageProvider p) {
  final done = Completer<void>();
  final stream = p.resolve(ImageConfiguration.empty);
  late final ImageStreamListener l;
  l = ImageStreamListener(
    (_, _) {
      if (!done.isCompleted) done.complete();
      stream.removeListener(l);
    },
    onError: (_, _) {
      if (!done.isCompleted) {
        done.complete(); // missing image: card shows fallback
      }
      stream.removeListener(l);
    },
  );
  stream.addListener(l);
  return done.future;
}

/// Renders [ScoreCard] off-screen to PNG bytes.
Future<Uint8List> renderScoreCard(
  ScoreCardData data, {
  required Locale locale,
  double pixelRatio = 3,
}) async {
  await Future.wait(scoreCardImageProviders(data).map(_warm));
  final l10n = await AppLocalizations.delegate.load(locale);

  final boundary = RenderRepaintBoundary();
  final dispatcher = ui.PlatformDispatcher.instance;
  final view = dispatcher.implicitView ?? dispatcher.views.first;
  final pipeline = PipelineOwner();
  final renderView = RenderView(
    view: view,
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(_cardSize),
      physicalConstraints: BoxConstraints.tight(_cardSize),
      devicePixelRatio: 1,
    ),
    child: RenderPositionedBox(alignment: Alignment.center, child: boundary),
  );
  pipeline.rootNode = renderView;
  renderView.prepareInitialFrame();

  final focus = FocusManager();
  final build = BuildOwner(focusManager: focus);
  RenderObjectToWidgetAdapter<RenderBox>? adapter;
  RenderObjectToWidgetElement<RenderBox>? root;
  ui.Image? image;
  try {
    adapter = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: _cardSize),
          child: Theme(
            data: buildTheme(),
            child: Localizations(
              locale: locale,
              delegates: [
                _Fixed<AppLocalizations>(l10n),
                DefaultWidgetsLocalizations.delegate,
              ],
              child: ScoreCard(data: data),
            ),
          ),
        ),
      ),
    );
    root = adapter.attachToRenderTree(build);
    build.buildScope(root);
    pipeline
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();
    image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  } finally {
    image?.dispose();
    if (root != null) {
      // Unmount so nothing keeps listening to the shared image cache.
      RenderObjectToWidgetAdapter<RenderBox>(
        container: boundary,
      ).attachToRenderTree(build, root);
      build.finalizeTree();
    }
    renderView.child = null;
    renderView.dispose();
    pipeline.rootNode = null;
    pipeline.dispose();
    focus.dispose();
  }
}

class _Fixed<T> extends LocalizationsDelegate<T> {
  const _Fixed(this.value);
  final T value;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<T> load(Locale locale) => SynchronousFuture<T>(value);
  @override
  bool shouldReload(covariant LocalizationsDelegate<T> old) => false;
}
