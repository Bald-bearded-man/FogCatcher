import 'dart:ui' as ui;

import 'package:flutter/services.dart';

const avatarSheetAsset = 'assets/tiles/avatars.png';

/// Tileset, sprite and avatar atlases, decoded once at start-up.
class SpriteSheets {
  const SpriteSheets({
    required this.tiles,
    required this.sprites,
    required this.avatars,
  });
  final ui.Image tiles, sprites;
  final ui.Image avatars; // one row, see Avatar.frame

  static Future<SpriteSheets> load(AssetBundle b) async => SpriteSheets(
    tiles: await _decode(b, 'assets/tiles/tileset.png'),
    sprites: await _decode(b, 'assets/tiles/sprites.png'),
    avatars: await _decode(b, avatarSheetAsset),
  );

  static Future<ui.Image> _decode(AssetBundle b, String key) async {
    final data = await b.load(key);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }
}
