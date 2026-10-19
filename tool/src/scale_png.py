"""Scales one square PNG to several sizes.

Usage: python3 -E -P tool/src/scale_png.py <src.png> <size>:<dest.png> [...]
Needs Pillow. Called by tool/apply_pack.dart for the notification icon.
"""
import pathlib
import sys

from PIL import Image


def main(src, targets):
    img = Image.open(src).convert("RGBA")
    for target in targets:
        size, dest = target.split(":", 1)
        out = pathlib.Path(dest)
        out.parent.mkdir(parents=True, exist_ok=True)
        img.resize((int(size), int(size)), Image.LANCZOS).save(out, optimize=True)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2:])
