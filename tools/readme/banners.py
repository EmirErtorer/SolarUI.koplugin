"""Draw the README's banners in SolarUI's garden style: the gilt title, the vine
divider and the download plaque. Text is turned into paths so GitHub shows it
exactly, with no font to load; the colours read on GitHub's light and dark pages.
Needs fontTools:
    python3 tools/readme/banners.py
"""
import math, os
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(REPO, "assets")
GOLD, DEEP, LEAF, STEM, BLOOM, CREAM = "#D4A946", "#8A6420", "#6E8F4E", "#3E5B3A", "#D9826A", "#F4E8C8"


def text_path(font_file, text, size, x=0, y=0, tracking=0):
    """The text as one SVG path, baseline at y; returns (d, width)."""
    font = TTFont(font_file)
    glyphs, cmap = font.getGlyphSet(), font.getBestCmap()
    scale = size / font["head"].unitsPerEm
    pen = SVGPathPen(glyphs)
    cx = x
    for ch in text:
        name = cmap.get(ord(ch))
        if not name:
            continue
        g = glyphs[name]
        g.draw(TransformPen(pen, (scale, 0, 0, -scale, cx, y)))
        cx += g.width * scale + tracking
    return pen.getCommands(), cx - x - tracking


def svg(w, h, body, label=None):
    role = f' role="img" aria-label="{label}"><title>{label}</title>' if label else ' aria-hidden="true">'
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"{role}{body}</svg>'


def leaf(x, y, rot, length, fill=LEAF):
    w = length * 0.42
    return (f'<g transform="translate({x:.1f} {y:.1f}) rotate({rot:.1f})"><path d="M0 0 C{length*.25:.1f} {-w:.1f} {length*.75:.1f} {-w:.1f} {length:.1f} 0 '
            f'C{length*.7:.1f} {w*.8:.1f} {length*.3:.1f} {w*.8:.1f} 0 0Z" fill="{fill}" stroke="{STEM}" stroke-width="1.6"/></g>')


def sun(cx, cy, r):
    rays = []
    for i in range(16):
        a = math.radians(i * 22.5)
        tip = r * (1 if i % 2 == 0 else .8)
        s1, s2 = math.radians(i * 22.5 - 7), math.radians(i * 22.5 + 7)
        rays.append(f"M{cx + math.cos(s1) * r * .55:.1f} {cy + math.sin(s1) * r * .55:.1f} L{cx + math.cos(a) * tip:.1f} {cy + math.sin(a) * tip:.1f} "
                    f"L{cx + math.cos(s2) * r * .55:.1f} {cy + math.sin(s2) * r * .55:.1f}Z")
    petals = "".join(f'<g transform="translate({cx} {cy}) rotate({i * 45})"><path d="M0 0 C{r*.14:.1f} {-r*.12:.1f} {r*.12:.1f} {-r*.33:.1f} 0 {-r*.4:.1f} '
                     f'C{-r*.12:.1f} {-r*.33:.1f} {-r*.14:.1f} {-r*.12:.1f} 0 0Z" fill="{BLOOM}" stroke="{DEEP}" stroke-width="1.2"/></g>' for i in range(8))
    return (f'<path d="{" ".join(rays)}" fill="{GOLD}" stroke="{DEEP}" stroke-width="1.8" stroke-linejoin="round"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r*.58:.1f}" fill="{GOLD}" stroke="{DEEP}" stroke-width="2.4"/>{petals}'
            f'<circle cx="{cx}" cy="{cy}" r="{r*.12:.1f}" fill="{DEEP}"/>')


def title(display_font):
    d, w = text_path(display_font, "SolarUI", 118, 150, 118, 2)
    W, H = int(w + 176), 160
    gilt = f'<path d="{d}" fill="{GOLD}" stroke="{DEEP}" stroke-width="3" stroke-linejoin="round"/>'
    vine = f'M150 146 C{150 + w*.25:.0f} 132 {150 + w*.55:.0f} 158 {150 + w*.85:.0f} 140 C{150 + w*.95:.0f} 134 {150 + w + 6:.0f} 126 {150 + w:.0f} 118'
    leaves = leaf(150 + w * .2, 140, -160, 22) + leaf(150 + w * .45, 147, -20, 20) + leaf(150 + w * .7, 146, 160, 20)
    return svg(W, H, sun(66, 82, 58) + f'<path d="{vine}" fill="none" stroke="{STEM}" stroke-width="4" stroke-linecap="round"/>' + leaves + gilt, "SolarUI")


def divider():
    W, H = 1000, 40
    vine = "M0 22 C120 6 220 36 340 20 C440 8 520 30 600 22 C700 12 820 30 1000 20"
    leaves = "".join(leaf(x, y, r, 18, LEAF) for x, y, r in [(90, 14, -150), (210, 30, 20), (330, 20, -140), (470, 22, 30), (660, 16, -150), (800, 26, 20), (920, 22, -160)])
    bloom = sun(560, 22, 14)
    return svg(W, H, f'<path d="{vine}" fill="none" stroke="{STEM}" stroke-width="3.5" stroke-linecap="round"/>{leaves}{bloom}')


def download(ui_font):
    d, w = text_path(ui_font, "Download the latest release", 21, 62, 31, 0.6)
    W, H = int(w + 92), 48
    plaque = f'<path d="M24 1 H{W - 24} A23 23 0 0 1 {W - 24} 47 H24 A23 23 0 0 1 24 1Z" fill="{STEM}" stroke="{GOLD}" stroke-width="2"/>'
    arrow = (f'<g transform="translate(26 11)" fill="none" stroke="{GOLD}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round">'
             f'<path d="M12 2 V17 M6 11 L12 17 L18 11 M4 23 H20"/></g>')
    return svg(W, H, f'{plaque}{arrow}<path d="{d}" fill="{CREAM}"/>', "Download the latest release")


if __name__ == "__main__":
    fonts = os.path.join(REPO, "fonts")
    os.makedirs(OUT, exist_ok=True)
    for name, data in [("solarui-title.svg", title(os.path.join(fonts, "Griffy-Regular.ttf"))), ("readme-divider.svg", divider()),
                       ("readme-download.svg", download(os.path.join(fonts, "Gabriela-Regular.ttf")))]:
        open(os.path.join(OUT, name), "w").write(data)
        print("wrote assets/" + name, len(data), "bytes")
