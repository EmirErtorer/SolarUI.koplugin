#!/usr/bin/env python3
"""The GitHub social preview (1280 x 640) on SolarUI's paper: the README's
header (the gilt title over the home dock's runner and plants), a line saying
what SolarUI is, and home and the garden standing side by side.
Needs rsvg-convert, and the screenshots from tools/readme/shots.sh:
    python3 tools/readme/social.py   ->  assets/social-preview.png"""
import os, subprocess, tempfile
from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO = os.path.realpath(os.path.join(os.path.dirname(__file__), "..", ".."))
PAPER, INK, MUTED, GOLD, RULE = (244, 236, 216), (43, 42, 34), (107, 101, 82), (197, 154, 62), (205, 191, 156)
W, H = 1280, 640


def font(name, size):
    return ImageFont.truetype(os.path.join(REPO, "fonts", name), size)


def screen(path, width):
    im = Image.open(os.path.join(REPO, "assets", "screenshots", path)).convert("RGB")
    im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.width - 1, im.height - 1), 18, fill=255)
    out = Image.new("RGBA", im.size)
    out.paste(im, (0, 0), mask)
    return out


def place(canvas, im, x, y):
    shadow = Image.new("RGBA", (im.width + 80, im.height + 80), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((40, 50, 40 + im.width, 50 + im.height), 18, fill=(60, 45, 20, 90))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(14)), (x - 40, y - 40))
    canvas.alpha_composite(im, (x, y))
    ImageDraw.Draw(canvas).rounded_rectangle((x, y, x + im.width - 1, y + im.height - 1), 18, outline=(90, 75, 50, 140), width=2)


img = Image.new("RGBA", (W, H), PAPER + (255,))
d = ImageDraw.Draw(img)
d.rectangle((14, 14, W - 15, H - 15), outline=RULE, width=3)
d.rectangle((24, 24, W - 25, H - 25), outline=RULE, width=1)

# the header, rasterised from the README's own SVG
with tempfile.TemporaryDirectory() as tmp:
    png = os.path.join(tmp, "header.png")
    subprocess.run(["rsvg-convert", "-w", "760", os.path.join(REPO, "assets", "solarui-header.svg"), "-o", png], check=True)
    header = Image.open(png).convert("RGBA")
img.alpha_composite(header, (40, 120))

# what it is, in two quiet lines
lines = ["An Art Nouveau garden of a home screen", "for KOReader. Read, and the garden grows."]
f = font("Gabriela-Regular.ttf", 34)
for i, line in enumerate(lines):
    d.text((72, 340 + i * 50), line, font=f, fill=INK)
small = font("Gabriela-Regular.ttf", 24)
d.text((72, 470), "32 companions  ·  a garden your reading grows", font=small, fill=MUTED)

# home and the garden, side by side on the right
place(img, screen("02-garden.png", 300), 948, 160)
place(img, screen("01-home.png", 320), 800, 70)
img.convert("RGB").save(os.path.join(REPO, "assets", "social-preview.png"), optimize=True)
print("wrote assets/social-preview.png")
