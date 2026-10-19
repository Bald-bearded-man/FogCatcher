"""Builds assets/tiles/tileset.png and sprites.png from Kenney packs (CC0).

Usage: python3 tool/mapgen/make_tiles.py <tiny-town-dir> <tiny-dungeon-dir>
Both dirs are the extracted zips from https://kenney.nl/assets/tiny-town and
https://kenney.nl/assets/tiny-dungeon. Layout must match lib/models/tileset_layout.dart.
"""
import sys

from PIL import Image, ImageOps

T = 16
COLS = 8
BLUE = (0x5B, 0x9B, 0xD5)
BLUE_DEEP = (0x11, 0x73, 0xBC)
ACCENT_ORANGE = (0xF2, 0x65, 0x30)
PAPER = (0xF2, 0xF2, 0xF2)
CLOSED_CHEST_GREY = 0.5


def tile(sheet, index, cols=12):
    x, y = (index % cols) * T, (index // cols) * T
    return sheet.crop((x, y, x + T, y + T))


def tint(img, dark, light):
    """Recolours a tile by luminance so the Kenney texture survives."""
    alpha = img.getchannel("A")
    out = ImageOps.colorize(ImageOps.autocontrast(img.convert("L")), dark, light).convert("RGBA")
    out.putalpha(alpha)
    return out


def greyer(img, amount):
    """Blends towards greyscale so the unfound chest reads duller than the found one."""
    alpha = img.getchannel("A")
    grey = ImageOps.grayscale(img).convert("RGBA")
    out = Image.blend(img, grey, amount)
    out.putalpha(alpha)
    return out


def seal(img):
    """Paints the dark slit under the closed chest's lid with body wood, so it doesn't read as ajar."""
    out = img.copy()
    px = out.load()
    outline, wood = px[0, 3], px[3, 12]
    for y in range(9, 12):
        for x in range(3, 13):
            if px[x, y] == outline:
                px[x, y] = wood
    return out


def speckle(img, seed, dark, light):
    """Adds a fixed sprinkle of pixels so flat tiles read as ground, not UI."""
    out = img.copy()
    px = out.load()
    for i in range(10):
        x, y = (seed * 7 + i * 5) % T, (seed * 3 + i * 11) % T
        px[x, y] = (dark if i % 2 else light) + (255,)
    return out


def roof():
    # Own CC0 tile: flat terracotta, darker bottom/right edge so adjacent cells read as blocks.
    img = Image.new("RGBA", (T, T), (0xC8, 0x64, 0x3C, 255))
    edge = (0x8E, 0x40, 0x24, 255)
    for i in range(T):
        img.putpixel((T - 1, i), edge)
        img.putpixel((i, T - 1), edge)
    return img


def water():
    # Tiny Town has no water: own CC0 tile, seamless.
    img = Image.new("RGBA", (T, T), (0x3F, 0x8F, 0xD8, 255))
    px = img.load()
    for x, y in [(2, 3), (3, 2), (4, 2), (5, 3), (10, 9), (11, 8), (12, 8), (13, 9),
                 (6, 13), (7, 12), (8, 12), (9, 13)]:
        px[x, y] = (0x9C, 0xCB, 0xF2, 255)
    for x, y in [(3, 4), (4, 4), (11, 10), (12, 10), (7, 14), (8, 14)]:
        px[x, y] = (0x2F, 0x6F, 0xB8, 255)
    return img


def sparkle(frame):
    # Own CC0 frames: a star that grows, flashes, then scatters.
    img = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    px = img.load()
    c = 7
    orange, hot = ACCENT_ORANGE + (255,), PAPER + (255,)
    arms = [1, 3, 5, 0][frame]
    for d in range(1, arms + 1):
        for x, y in [(c + d, c), (c - d, c), (c, c + d), (c, c - d)]:
            px[x, y] = orange
    if frame in (1, 2):
        px[c, c] = hot
    if frame == 2:
        for d in (1, 2):
            for x, y in [(c + d, c + d), (c - d, c - d), (c + d, c - d), (c - d, c + d)]:
                px[x, y] = orange
    if frame == 0:
        px[c, c] = orange
    if frame == 3:
        for x, y in [(2, 2), (13, 3), (3, 12), (12, 13), (7, 1), (14, 8), (1, 7), (8, 14)]:
            px[x, y] = orange
    return img


def main(town_dir, dungeon_dir):
    town = Image.open(f"{town_dir}/Tilemap/tilemap_packed.png").convert("RGBA")
    dungeon = Image.open(f"{dungeon_dir}/Tilemap/tilemap_packed.png").convert("RGBA")
    grass, dirt, slab = (tile(town, i) for i in (1, 25, 109))
    wood = grass.copy()
    wood.alpha_composite(tile(town, 28))
    tiles = [
        grass,                                              # 0 grass
        wood,                                               # 1 wood
        speckle(tint(dirt, (0xB8, 0x9A, 0x5A), (0xF4, 0xE6, 0xB0)), 1,
                (0xD8, 0xC0, 0x80), (0xFF, 0xF4, 0xD0)),     # 2 sand
        slab,                                               # 3 court
        speckle(tint(slab, (0x5A, 0x5A, 0x60), (0xA8, 0xA8, 0xB0)), 2,
                (0x80, 0x80, 0x88), (0xB8, 0xB8, 0xC0)),     # 4 parking
        speckle(tint(slab, (0x2A, 0x2A, 0x30), (0x60, 0x60, 0x68)), 3,
                (0x40, 0x40, 0x48), (0x70, 0x70, 0x78)),     # 5 road
        dirt,                                               # 6 path
        water(),                                            # 7 water
        roof(),                                             # 8 building
    ]
    sheet = Image.new("RGBA", (COLS * T, 2 * T), (0, 0, 0, 0))
    for i, t in enumerate(tiles):
        sheet.paste(t, ((i % COLS) * T, (i // COLS) * T))
    sheet.save("assets/tiles/tileset.png", optimize=True)

    player = tile(dungeon, 98)
    recolour = {
        (192, 203, 220): (0x9C, 0xC6, 0xEA),
        (139, 155, 180): BLUE,
        (82, 96, 124): BLUE_DEEP,
    }
    px = player.load()
    for y in range(T):
        for x in range(T):
            r, g, b, a = px[x, y]
            if (r, g, b) in recolour:
                px[x, y] = recolour[(r, g, b)] + (a,)
    frames = [player, greyer(seal(tile(dungeon, 90)), CLOSED_CHEST_GREY), tile(dungeon, 91)] + [sparkle(f) for f in range(4)]
    sprites = Image.new("RGBA", (len(frames) * T, T), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sprites.paste(f, (i * T, 0))
    sprites.save("assets/tiles/sprites.png", optimize=True)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
