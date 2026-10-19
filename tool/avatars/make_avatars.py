"""Draws the 10 player avatars into assets/tiles/avatars.png.

Usage: python3 tool/avatars/make_avatars.py [preview.png]
One row of 16 px frames; avatar i is at frames 2i (idle) and 2i+1 (bob).
Order must match lib/models/avatar.dart. All art is original.
"""
import os
import sys

from PIL import Image

T = 16
OUTLINE = (0x1A, 0x1A, 0x1A)
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "assets", "tiles", "avatars.png")

PALETTE = {
    "K": OUTLINE,
    "s": (0xF1, 0xC2, 0x7D),  # skin
    "S": (0xD9, 0x9A, 0x5E),  # skin shadow
    "h": (0x6B, 0x3E, 0x26),  # hair
    "b": (0x5B, 0x9B, 0xD5),  # blue tunic
    "B": (0x2F, 0x5F, 0x9A),  # dark blue
    "w": (0xF2, 0xF2, 0xF2),
    "p": (0x6D, 0x5A, 0xA6),  # purple
    "P": (0x4B, 0x3C, 0x7A),
    "y": (0xFF, 0xD5, 0x4F),
    "r": (0xD9, 0x41, 0x3A),
    "R": (0x9E, 0x26, 0x26),
    "l": (0xD6, 0xDA, 0xE0),  # silver
    "g": (0xA0, 0xA4, 0xAA),
    "G": (0x6C, 0x70, 0x78),
    "n": (0x5A, 0x3A, 0x22),  # boots
    "t": (0x8B, 0x5A, 0x2B),  # wood
    "o": (0xF2, 0x65, 0x30),  # orange
    "q": (0xE6, 0x51, 0x68),  # pink
    "x": (0x9B, 0xD8, 0x7A),  # alien skin
    "X": (0x5E, 0xA8, 0x4E),
    "m": (0x4C, 0xC2, 0x5A),  # slime
    "M": (0x24, 0x80, 0x3A),
    "c": (0x6F, 0xC8, 0xF2),  # visor
    "C": (0x11, 0x73, 0xBC),
    "k": (0x34, 0x34, 0x40),  # ninja cloth
    "L": (0xFF, 0x3B, 0x3B),  # robot light on
    "D": (0x5A, 0x22, 0x22),  # robot light off
}

# Each avatar: (name, idle grid, bob) where bob is the torso row to drop
# (everything above slides down 1 px) or a full second grid.
AVATARS = [
    ("explorer_girl", [
        "................",
        "................",
        ".....hhhhhh.....",
        "....hhhhhhhhh...",
        "....hhhhhhhhqh..",
        "....hssssssh.hh.",
        "....sKssssKs..h.",
        "....ssssssss..h.",
        ".....ssSSss.....",
        "....bbbbbbbb....",
        "...sbbbbbbbbs...",
        "...sbbbbbbbbs...",
        "....bbbbbbbb....",
        ".....ss..ss.....",
        ".....nn..nn.....",
        "................",
    ], 10),
    ("explorer_boy", [
        "................",
        "................",
        ".....oooooo.....",
        "....oooooooo....",
        "....oooooooooo..",
        "....hssssssh....",
        "....sKssssKs....",
        "....ssssssss....",
        ".....ssSSss.....",
        "....bbbbbbbb....",
        "...sbbbbbbbbs...",
        "...sbbbbbbbbs...",
        "....nnnynnnn....",
        ".....BB..BB.....",
        ".....nn..nn.....",
        "................",
    ], 10),
    ("mage", [
        "................",
        "..y.......p.....",
        ".yyy.....pp.....",
        "..y.....ppp.....",
        "..t....pppp.....",
        "..t...ppyppp....",
        "..t.pppppppppp..",
        "..t...sKssKs....",
        "..t...ssssss....",
        "..ts.ppwwwwpp...",
        "..t.pppwwwwppp..",
        "..t.ppppwwpppp..",
        "..t.pppppppppp..",
        "..t.PPPPPPPPPP..",
        "..t...nn..nn....",
        "................",
    ], 12),
    ("knight", [
        "................",
        "........rrr.....",
        ".......rrr......",
        ".....llllll.....",
        "....llllllll....",
        "....lKKKKKKl....",
        "....llllllll....",
        "....gllllllg....",
        ".....gggggg.....",
        ".GGGGlllllllg...",
        ".GbbGrrrrrrlg...",
        ".GbyGrrrrrrlg...",
        ".GbbGrrrrrr.....",
        "..GG..gg..gg....",
        "......GG..GG....",
        "................",
    ], 11),
    ("alien", [
        "................",
        "...y........y...",
        "....x......x....",
        ".....xxxxxx.....",
        "....xxxxxxxx....",
        "...xxxxxxxxxx...",
        "...xwKKxxwKKx...",
        "...xKKKxxKKKx...",
        "...xxKKxxKKxx...",
        "....xxxxxxxx....",
        ".....xxxxxx.....",
        "....xppppppx....",
        ".....pppppp.....",
        ".....pp..pp.....",
        ".....XX..XX.....",
        "................",
    ], 11),
    ("robot", [
        "................",
        ".......L........",
        ".......G........",
        "....GGGGGGGG....",
        "....GggggggG....",
        "....GcKggcKG....",
        "....GggggggG....",
        "....GgKKKKgG....",
        "....GGGGGGGG....",
        "......GGGG......",
        "..GGggggggggGG..",
        "..GGgglyylggGG..",
        "....gggggggg....",
        ".....GG..GG.....",
        "....GGG..GGG....",
        "................",
    ], 12),
    ("ninja", [
        "................",
        "................",
        ".....kkkkkk.....",
        "....kkkkkkkk....",
        "....rrrrrrrrrr..",
        "....kkkkkkkk.rr.",
        "....sKssssKs....",
        "....kkkkkkkk....",
        ".....kkkkkk.....",
        "....kkkkkkkk....",
        "...kkkkkkkkkk...",
        "...skkkkkkkks...",
        "....GGGGGGGG....",
        ".....kk..kk.....",
        ".....kk..kk.....",
        "................",
    ], 10),
    ("pirate", [
        "................",
        "................",
        ".....rrrrrr.....",
        "....rrwrrwrr....",
        "....rrrrrrrrrr..",
        "....hssssssh.r..",
        "....sKKssKss....",
        "....ssKKssss....",
        ".....shhhhs.....",
        "....wwwwwwww....",
        "...sBBBBBBBBs...",
        "...swwwwwwwws...",
        "....BBBBBBBB....",
        ".....nn..nn.....",
        ".....nn..nn.....",
        "................",
    ], 12),
    ("astronaut", [
        "................",
        "................",
        ".....wwwwww.....",
        "....wwwwwwww....",
        "...wwCCCCCCww...",
        "...wCcwccccCw...",
        "...wCccccccCw...",
        "...wwCCCCCCww...",
        "....wwwwwwww....",
        "...gwwwwwwwwg...",
        "..gwwwoowwwwwg..",
        "..wwwwwwwwwwww..",
        "...gwwwwwwwwg...",
        ".....ww..ww.....",
        ".....gg..gg.....",
        "................",
    ], 11),
    ("slime", [
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "......mmmm......",
        "....mmmmmmmm....",
        "...mmwmmmmmmm...",
        "...mwmmmmmmmm...",
        "..mmmmKmmKmmmm..",
        "..mmmmKmmKmmmm..",
        "..mmmmmmmmmmmm..",
        "..MmmmmmmmmmmM..",
        "...MMMMMMMMMM...",
        "................",
    ], [
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        ".....mmmmmm.....",
        "...mmwmmmmmmm...",
        "..mmwmmmmmmmmm..",
        ".mmmmmKmmKmmmmm.",
        ".mmmmmKmmKmmmmm.",
        ".MmmmmmmmmmmmmM.",
        "..MMMMMMMMMMMM..",
        "................",
    ]),
]


def bob(grid, drop):
    """Slides the rows above [drop] down 1 px; rows below stay put."""
    return ["." * T] + grid[:drop] + grid[drop + 1:]


def draw(grid):
    assert len(grid) == T and all(len(r) == T for r in grid), grid
    img = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    px = img.load()
    for y, row in enumerate(grid):
        for x, ch in enumerate(row):
            if ch != ".":
                px[x, y] = PALETTE[ch] + (255,)
    # 1 px outline on the 4-neighbourhood so the shape reads on grass.
    filled = {(x, y) for y in range(T) for x in range(T) if px[x, y][3]}
    for x in range(T):
        for y in range(T):
            if (x, y) in filled:
                continue
            if any((x + dx, y + dy) in filled for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = OUTLINE + (255,)
    return img


def frames():
    for name, idle, second in AVATARS:
        if name == "robot":
            off = [r.replace("L", "D") for r in idle]
            yield draw(idle)
            yield draw(bob(off, second))
            continue
        yield draw(idle)
        yield draw(second if isinstance(second, list) else bob(idle, second))


def preview(sheet, path, scale=4):
    """Every frame on grass (top) and on the app's ink colour (bottom), upscaled."""
    grass = Image.open(os.path.join(ROOT, "assets", "tiles", "tileset.png")).convert("RGBA").crop((0, 0, T, T))
    n = sheet.width // T
    gap = 4
    out = Image.new("RGBA", (n * T + (n // 2) * gap, 2 * T + gap), (0x37, 0x36, 0x3B, 255))
    for i in range(n):
        x = i * T + (i // 2) * gap
        frame = sheet.crop((i * T, 0, (i + 1) * T, T))
        out.paste(grass, (x, 0))
        out.alpha_composite(frame, (x, 0))
        out.alpha_composite(frame, (x, T + gap))
    out = out.resize((out.width * scale, out.height * scale), Image.NEAREST)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out.save(path)


def main():
    sheet = Image.new("RGBA", (T * 2 * len(AVATARS), T), (0, 0, 0, 0))
    for i, f in enumerate(frames()):
        sheet.paste(f, (i * T, 0))
    sheet.save(OUT, optimize=True)
    if len(sys.argv) > 1:
        preview(sheet, sys.argv[1])


if __name__ == "__main__":
    main()
