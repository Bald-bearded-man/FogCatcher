"""Draws the demo pack's brand art.

Usage: python3 tool/art/make_demo_art.py
Writes pack/brand/*.png and assets/brand/logo.png. Everything is procedural and
deterministic; no source images.
"""
import json
import os
import shutil

from PIL import Image, ImageDraw

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
PACK = os.path.join(ROOT, "pack")


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def save_png(img, path):
    """Saves without text chunks, EXIF or ICC so outputs carry no metadata."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.info.clear()
    img.save(path, format="PNG", optimize=True)


def upscale(img, k):
    return img.resize((img.width * k, img.height * k), Image.NEAREST)


# ---------------------------------------------------------------- brand

G = 32  # brand glyph grid


HOOP = (12, 2, 29, 19)
HOOP_IN = (14, 4, 27, 17)
BAG = [(15, 17), (29, 12), (30, 21), (28, 27), (24, 30), (19, 27)]


def brand_layers():
    """The glyph as named masks: a butterfly net scooping up a fog cloud."""
    layers = {k: Image.new("L", (G, G), 0) for k in
              ("handle", "ring", "inside", "bag", "bag_edge", "mesh", "cloud", "wisp")}
    d = {k: ImageDraw.Draw(v) for k, v in layers.items()}

    d["handle"].line([(3, 29), (14, 17)], fill=255, width=3)
    d["ring"].ellipse(HOOP, outline=255, width=2)
    d["inside"].ellipse(HOOP_IN, fill=255)
    d["bag"].polygon(BAG, fill=255)
    d["bag_edge"].line(BAG[1:] + BAG[:1], fill=255)
    for y in range(G):
        for x in range(G):
            if (x + y) % 3 == 0 or (x - y) % 3 == 0:
                d["mesh"].point((x, y), fill=255)
    for cx, cy, r in ((17, 11, 2), (21, 9, 3), (24, 11, 2)):
        d["cloud"].ellipse((cx - r, cy - r, cx + r, cy + r), fill=255)
    d["cloud"].rectangle((16, 11, 25, 13), fill=255)
    # Fog still escaping on the left.
    d["wisp"].line([(3, 6), (8, 6)], fill=255)
    d["wisp"].line([(5, 9), (10, 9)], fill=255)
    d["wisp"].line([(2, 12), (7, 12)], fill=255)
    return layers


def mask_and(a, b):
    return Image.composite(a, Image.new("L", a.size, 0), b)


def mask_sub(a, b):
    return Image.composite(Image.new("L", a.size, 0), a, b)


def brand_glyph(pal, outline=True):
    """Full-colour glyph on a transparent 32x32 grid."""
    L = brand_layers()
    img = Image.new("RGBA", (G, G), (0, 0, 0, 0))

    def fill(mask, rgb):
        img.paste(rgb + (255,), (0, 0), mask)

    bag = mask_sub(L["bag"], L["inside"])
    fill(mask_and(bag, L["mesh"]), pal["primaryDeep"])
    fill(mask_sub(L["bag_edge"], L["inside"]), pal["primary"])
    fill(mask_sub(mask_and(L["inside"], L["mesh"]), L["cloud"]), pal["primaryDeep"])
    fill(L["cloud"], pal["paper"])
    # Underside shade: cloud pixels whose lower neighbour is not cloud.
    below = L["cloud"].transform((G, G), Image.AFFINE, (1, 0, 0, 0, 1, 1))
    fill(mask_sub(L["cloud"], below), pal["primary"])
    fill(L["wisp"], pal["primary"])
    fill(L["handle"], pal["shade"])
    fill(L["ring"], pal["accent"])
    px = img.load()
    for x, y in ((19, 8), (20, 7)):
        px[x, y] = (255, 255, 255, 255)
    for x, y in ((15, 4), (16, 3), (14, 5)):
        px[x, y] = pal["highlight"] + (255,)
    for x, y in ((5, 26), (7, 24), (9, 22)):
        px[x, y] = pal["highlight"] + (255,)
    if outline:
        add_outline(img, pal["ink"])
    return img


def brand_silhouette():
    """Solid shape for the notification glyph: ring, handle, cloud, bag outline."""
    L = brand_layers()
    m = Image.new("L", (G, G), 0)
    for k in ("handle", "ring", "cloud", "wisp"):
        m.paste(255, (0, 0), L[k])
    m.paste(255, (0, 0), mask_sub(L["bag_edge"], L["inside"]))
    m.paste(255, (0, 0), mask_and(mask_sub(L["bag"], L["inside"]), L["mesh"]))
    img = Image.new("RGBA", (G, G), (0, 0, 0, 0))
    img.paste((255, 255, 255, 255), (0, 0), m)
    return img


def add_outline(img, rgb):
    """1 px outline on the 4-neighbourhood so the glyph reads on light and dark."""
    px = img.load()
    w, h = img.size
    filled = {(x, y) for y in range(h) for x in range(w) if px[x, y][3]}
    for y in range(h):
        for x in range(w):
            if (x, y) in filled:
                continue
            if any((x + dx, y + dy) in filled for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = rgb + (255,)


def centered(glyph, size, k):
    """Glyph scaled by k, centred on a transparent size x size canvas."""
    big = upscale(glyph, k)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.alpha_composite(big, ((size - big.width) // 2, (size - big.height) // 2))
    return out


def make_brand(pal):
    brand = os.path.join(PACK, "brand")
    glyph = brand_glyph(pal)

    icon = Image.new("RGBA", (1024, 1024), pal["ink"] + (255,))
    # Scales keep every opaque pixel (~20 cells from centre) inside the circular masks.
    icon.alpha_composite(centered(glyph, 1024, 24))
    save_png(icon.convert("RGB"), os.path.join(brand, "icon.png"))

    # Adaptive icon safe zone: circle of 66% diameter (radius 338 px).
    save_png(centered(glyph, 1024, 16), os.path.join(brand, "icon_foreground.png"))
    # Android 12 splash crops to a circle of 2/3 the canvas (radius 256 px).
    save_png(centered(glyph, 768, 12), os.path.join(brand, "splash.png"))
    save_png(upscale(glyph, 8), os.path.join(brand, "logo.png"))
    save_png(upscale(brand_silhouette(), 3), os.path.join(brand, "ic_stat_notify.png"))

    dest = os.path.join(ROOT, "assets", "brand", "logo.png")
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copyfile(os.path.join(brand, "logo.png"), dest)


def main():
    with open(os.path.join(PACK, "pack.json"), encoding="utf-8") as f:
        pal = {k: hex_rgb(v) for k, v in json.load(f)["palette"].items()}
    make_brand(pal)


if __name__ == "__main__":
    main()
