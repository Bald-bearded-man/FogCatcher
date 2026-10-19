"""Resizes photos to fit a max edge and saves them as WebP (package:image cannot encode WebP).

Usage: python3 -E -P tool/src/webp.py <max_px> <src> <dst> [<src> <dst> ...]
Few-colour images (pixel art, drawings) are saved lossless, photos lossy at quality 80.
"""
import sys

from PIL import Image, ImageOps


def convert(max_px, src, dst):
    with Image.open(src) as im:
        im = ImageOps.exif_transpose(im)
        im = im.convert("RGBA" if "A" in im.getbands() else "RGB")
        im.thumbnail((max_px, max_px), Image.Resampling.LANCZOS)
        lossless = im.getcolors(256) is not None
        im.save(dst, "WEBP", lossless=lossless, quality=80, method=6)
        print(f"{dst} {im.width}x{im.height}{' lossless' if lossless else ''}")


def main(argv):
    if len(argv) < 4 or len(argv) % 2:
        sys.exit(__doc__)
    max_px = int(argv[1])
    for src, dst in zip(argv[2::2], argv[3::2]):
        convert(max_px, src, dst)


if __name__ == "__main__":
    main(sys.argv)
