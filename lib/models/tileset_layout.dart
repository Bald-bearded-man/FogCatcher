// coverage:ignore-file (declarations only)
import 'terrain.dart';

const tileSize = 16;
const tilesetColumns = 8;

/// Tile index in assets/tiles/tileset.png (row-major) per terrain; voidZone is drawn black, not from the sheet.
const terrainTileIndex = <Terrain, int>{
  Terrain.grass: 0,
  Terrain.wood: 1,
  Terrain.sand: 2,
  Terrain.court: 3,
  Terrain.parking: 4,
  Terrain.road: 5,
  Terrain.path: 6,
  Terrain.water: 7,
  Terrain.building: 8,
};

/// Frames in assets/tiles/sprites.png, one row of 16 px frames.
const spritePlayer = 0,
    spriteChestClosed = 1,
    spriteChestOpen = 2,
    spriteSparkleFirst = 3,
    spriteSparkleCount = 4;
