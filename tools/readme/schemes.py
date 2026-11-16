"""The README's colour scheme collage: home in each of SolarUI's five schemes,
light above and dark below, each pair under the scheme's name and a strip of
its colours, on SolarUI's paper with soft shadows and rounded screens.
    python3 tools/readme/schemes.py <folder with s-<scheme>-<mode>.png> <out.png>
"""
import os, re, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC, OUT = sys.argv[1], sys.argv[2]
SCHEMES = [("garden", "Garden"), ("rosewood", "Rosewood"), ("peacock", "Peacock"), ("sepia", "Sepia"), ("custom", "Custom")]
CUSTOM = {"accent": "#6B3A6B", "accent2": "#D08A2E"}   # (as tools/readme/schemes.lua sets them)
PAPER, INK, MUTED, GOLD, RULE = (244, 236, 216), (43, 42, 34), (120, 112, 92), (197, 154, 62), (205, 191, 156)
TITLE = os.path.join(REPO, "fonts", "Griffy-Regular.ttf")
TEXT = os.path.join(REPO, "fonts", "Gabriela-Regular.ttf")

SHOT_W, GAP, SIDE, RADIUS = 440, 56, 72, 22


def palette(scheme, mode):
    """The scheme's page colours for a mode, from its theme file."""
    path = os.path.join(REPO, "solarui", "themes", ("garden" if scheme == "custom" else scheme) + ".lua")
    src = open(path).read()
    block = re.search(mode + r"\s*=\s*\{(.*?)\n\s*\}", src, re.S).group(1)
    pal = dict(re.findall(r"(\w+)\s*=\s*\"(#[0-9A-Fa-f]{6})\"", block))
    if scheme == "custom":
        pal.update(CUSTOM)
    return pal


def hexrgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def rounded(im, r):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.width - 1, im.height - 1), r, fill=255)
    out = Image.new("RGBA", im.size)
    out.paste(im, (0, 0), mask)
    return out


def place(canvas, im, x, y):
    """A screen with a soft shadow under it and a hairline round it."""
    shadow = Image.new("RGBA", (im.width + 80, im.height + 80), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((40, 48, 40 + im.width, 48 + im.height), RADIUS, fill=(60, 45, 20, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(16))
    canvas.alpha_composite(shadow, (x - 40, y - 40))
    canvas.alpha_composite(rounded(im, RADIUS), (x, y))
    ImageDraw.Draw(canvas).rounded_rectangle((x, y, x + im.width - 1, y + im.height - 1), RADIUS, outline=(90, 75, 50, 120), width=2)


def tag(draw, cx, cy, text, dark, font):
    """A small pill naming the mode, centred on (cx, cy), just under its screen."""
    box = draw.textbbox((0, 0), text, font=font)
    w, h = box[2] - box[0] + 28, box[3] - box[1] + 16
    x, y = cx - w // 2, cy - h // 2
    fill, ink = ((24, 30, 26, 230), (240, 230, 204)) if dark else ((251, 244, 226, 235), INK)
    draw.rounded_rectangle((x, y, x + w, y + h), h // 2, fill=fill, outline=GOLD + (255,), width=2)
    draw.text((x + 14 - box[0], y + 8 - box[1]), text, font=font, fill=ink)


shots = {}
for s, _n in SCHEMES:
    for m in ("light", "dark"):
        im = Image.open(os.path.join(SRC, f"s-{s}-{m}.png")).convert("RGB")
        shots[s, m] = im.resize((SHOT_W, round(im.height * SHOT_W / im.width)), Image.LANCZOS)
shot_h = shots["garden", "light"].height
head_h, name_h, row_gap, foot = 170, 118, 84, 128
W = SIDE * 2 + len(SCHEMES) * SHOT_W + (len(SCHEMES) - 1) * GAP
H = head_h + name_h + shot_h * 2 + row_gap + foot
canvas = Image.new("RGBA", (W, H), PAPER + (255,))
d = ImageDraw.Draw(canvas)

# the heading: a gilt title over a vine rule
title_font, name_font = ImageFont.truetype(TITLE, 84), ImageFont.truetype(TITLE, 50)
small = ImageFont.truetype(TEXT, 24)
sub_font = ImageFont.truetype(TEXT, 30)
title = "Five colour schemes, light and dark"
box = d.textbbox((0, 0), title, font=title_font)
tx = (W - (box[2] - box[0])) // 2
d.text((tx + 3, 54 + 3), title, font=title_font, fill=(138, 100, 32))
d.text((tx, 54), title, font=title_font, fill=GOLD)
rule_y = 150
d.line((SIDE, rule_y, W - SIDE, rule_y), fill=RULE, width=3)
for cx in (W // 2,):
    d.ellipse((cx - 9, rule_y - 9, cx + 9, rule_y + 9), fill=GOLD, outline=(138, 100, 32), width=2)

for i, (s, name) in enumerate(SCHEMES):
    x = SIDE + i * (SHOT_W + GAP)
    y = head_h
    # the scheme's name and its colours
    box = d.textbbox((0, 0), name, font=name_font)
    d.text((x + (SHOT_W - (box[2] - box[0])) // 2, y + 6), name, font=name_font, fill=INK)
    pal = palette(s, "light")
    swatches = [pal["bg"], pal["ink"], pal["accent"], pal["accent2"], pal.get("gold", "#E0A83A")]
    sw, sgap = 46, 12
    total = len(swatches) * sw + (len(swatches) - 1) * sgap
    sx, sy = x + (SHOT_W - total) // 2, y + 74
    for k, hx in enumerate(swatches):
        cx = sx + k * (sw + sgap)
        d.rounded_rectangle((cx, sy, cx + sw, sy + 24), 12, fill=hexrgb(hx) + (255,), outline=(90, 75, 50, 150), width=2)
    # light above, dark below
    for j, m in enumerate(("light", "dark")):
        yy = head_h + name_h + j * (shot_h + row_gap)
        place(canvas, shots[s, m].convert("RGBA"), x, yy)
        tag(d, x + SHOT_W // 2, yy + shot_h + 34, "Light" if m == "light" else "Dark", m == "dark", small)

note = "Every scheme has a dark mode, or follows KOReader's night mode"
box = d.textbbox((0, 0), note, font=sub_font)
d.text(((W - (box[2] - box[0])) // 2, H - 52), note, font=sub_font, fill=MUTED)
canvas.convert("RGB").save(OUT, optimize=True)
print("wrote", OUT, canvas.size)
