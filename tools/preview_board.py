# -*- coding: utf-8 -*-
"""Composites the board the way fn_drawBoard lays it out, so layout changes can
be judged without launching Arma. Uses the PNGs written by gen_assets.py.

    python tools/preview_board.py      -> tools/.preview/board.png

The LAYOUT numbers below are the same fractions of the board rectangle that
fn_drawBoard.sqf uses. Keep them in step.
"""
import os
import random

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PNG = os.path.join(ROOT, "tools", ".png")
OUT = os.path.join(ROOT, "tools", ".preview")
os.makedirs(OUT, exist_ok=True)

BW, BH = 1400, 452

LAYOUT = {
    "shell":    (0.100, 0.200, 0.890, 0.700),
    "pack":     (0.012, 0.060, 0.135, 0.880),
    "junction": (0.835, 0.080, 0.150, 0.840),
    "left": 0.215, "right": 0.875, "top": 0.150, "bottom": 0.880,
    "tagX": 0.150, "tagW": 0.068,
}
TAPES = [(0.135, 0.090), (0.400, 0.055), (0.600, 0.055)]
PAD_FACTOR = [0.5, 0.5, 1.0]
PALETTE = [(168, 51, 43), (43, 79, 143), (201, 166, 43), (64, 122, 66), (201, 196, 181),
           (112, 74, 135), (189, 107, 36), (107, 74, 48), (33, 33, 31), (97, 99, 92)]


def sprite(name):
    return Image.open(os.path.join(PNG, name + ".png")).convert("RGBA")


def place(canvas, img, box, tint=None, alpha=1.0):
    x, y, w, h = box
    pw, ph = max(1, int(w * BW)), max(1, int(h * BH))
    s = img.resize((pw, ph), Image.BILINEAR)
    if tint or alpha < 1:
        r, g, b, a = s.split()
        if tint:
            r = r.point(lambda v: v * tint[0] // 255)
            g = g.point(lambda v: v * tint[1] // 255)
            b = b.point(lambda v: v * tint[2] // 255)
        if alpha < 1:
            a = a.point(lambda v: int(v * alpha))
        s = Image.merge("RGBA", (r, g, b, a))
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    layer.paste(s, (int(x * BW), int(y * BH)))
    return Image.alpha_composite(canvas, layer)


def dirt_layout(seed):
    """Mirror of the soil placement in fn_generatePuzzle."""
    random.seed(seed)
    out = []
    for row in range(2):
        for col in range(6):
            cx = (col + 0.5) / 6 + random.uniform(-0.035, 0.035)
            cy = (row + 0.5) / 2 + random.uniform(-0.08, 0.08)
            out.append((cx, cy, random.uniform(0.19, 0.235), random.randrange(4)))
    return out


def board(n, stage):
    c = Image.new("RGBA", (BW, BH), (0, 0, 0, 255))
    c = place(c, sprite("ground_co"), (0, 0, 1, 1))
    c = place(c, sprite("shell_ca"), LAYOUT["shell"])
    c = place(c, sprite("pack_ca"), LAYOUT["pack"])
    ends = []

    random.seed(7)
    top, bottom = LAYOUT["top"], LAYOUT["bottom"]
    row_h = (bottom - top) / (n - 1)
    rows = [top + i * row_h + random.uniform(-1.2, 1.2) * 0.09 * row_h for i in range(n)]
    span = LAYOUT["right"] - LAYOUT["left"]

    for i in range(n):
        end = max(0, min(n - 1, i + random.choice([-2, -1, 0, 1, 2])))
        travel = end - i
        pad = PAD_FACTOR[abs(travel)] * row_h
        name = "cable_d%s%d_%s" % ("m" if travel < 0 else "p", abs(travel), random.choice("ab"))
        y0, y1 = rows[i], rows[end]
        c = place(c, sprite(name), (LAYOUT["left"], min(y0, y1) - pad, span, abs(y1 - y0) + 2 * pad),
                  tint=PALETTE[i * 3 % len(PALETTE)])
        ends.append(y1)

    # Junction over the cable ends, then a crimp ferrule where each one enters.
    c = place(c, sprite("junction_ca"), LAYOUT["junction"])
    dj = ImageDraw.Draw(c)
    for y in ends:
        dj.rectangle([0.846 * BW, (y - 0.010) * BH, 0.866 * BW, (y + 0.010) * BH], fill=(92, 92, 84, 255))
        dj.rectangle([0.846 * BW, (y + 0.006) * BH, 0.866 * BW, (y + 0.010) * BH], fill=(31, 31, 28, 255))

    d = ImageDraw.Draw(c)
    for i in range(n):
        y = rows[i]
        d.rectangle([0.140 * BW, (y - 0.007) * BH, 0.222 * BW, (y + 0.007) * BH], fill=(26, 26, 24, 255))
    for i in range(n):
        y = rows[i]
        th = min(row_h * 0.5, 0.10)
        c = place(c, sprite("tag_ca"), (LAYOUT["tagX"], y - th / 2, LAYOUT["tagW"], th))
        ImageDraw.Draw(c).text((LAYOUT["tagX"] * BW + 44, (y - 0.02) * BH), str(i + 1), fill=(40, 34, 26, 255))

    if stage <= 1:
        for i, (x, w) in enumerate(TAPES):
            # The tag strip binds the tag column; the others wrap the shell only.
            y0, y1 = (0.08, 0.95) if i == 0 else (0.16, 0.94)
            c = place(c, sprite("tape_%s_ca" % "ab"[i % 2]), (x, y0, w, y1 - y0))
    if stage == 0:
        for cx, cy, size, v in dirt_layout(42):
            h = size * BW / BH
            c = place(c, sprite("dirt_%s_ca" % "abcd"[v]), (cx - size / 2, cy - h / 2, size, h))
    return c


if __name__ == "__main__":
    frames = [board(5, 0), board(5, 1), board(5, 2)]
    sheet = Image.new("RGBA", (BW, BH * 3 + 40), (20, 20, 18, 255))
    for i, f in enumerate(frames):
        sheet.paste(f, (0, i * (BH + 20)))
    path = os.path.join(OUT, "board.png")
    sheet.convert("RGB").save(path)
    print(path)
