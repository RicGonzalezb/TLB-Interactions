# -*- coding: utf-8 -*-
"""Composites the lockpicking board the way fn_drawCutaway / fn_drawFace and
fn_tick lay it out, from the PNGs written by gen_lockpick_assets.py.

    python tools/preview_lockpick.py    -> tools/.preview/lockpick.png

Frames: pin tumbler (5 pins, two set, one being lifted), rake mid-stroke with
the tension gauge, and the sweet-spot face with the plug part-turned.
"""
import math
import os
import random

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PNG = os.path.join(ROOT, "tools", ".png_lockpick")
OUT = os.path.join(ROOT, "tools", ".preview")
os.makedirs(OUT, exist_ok=True)

BW, BH = 1171, 383
ASPECT = BW / BH
CUT_TOP, CUT_SHEAR, CUT_KEYWAY, X0, X1, DRIVER = 0.06, 0.50, 0.86, 0.30, 0.80, 0.16
cache = {}


def sprite(name):
    if name not in cache:
        cache[name] = Image.open(os.path.join(PNG, name + ".png")).convert("RGBA")
    return cache[name]


def place(c, name, x, y, w, h, tint=None):
    s = sprite(name).resize((max(1, int(w * BW)), max(1, int(h * BH))), Image.BILINEAR)
    if tint:
        r, g, b, a = s.split()
        r, g, b = (ch.point(lambda v, k=k: v * k // 255) for ch, k in zip((r, g, b), tint))
        s = Image.merge("RGBA", (r, g, b, a))
    layer = Image.new("RGBA", c.size, (0, 0, 0, 0))
    layer.paste(s, (int(x * BW), int(y * BH)))
    return Image.alpha_composite(c, layer)


def fill(c, x, y, w, h, rgba):
    d = ImageDraw.Draw(c)
    d.rectangle([x * BW, y * BH, (x + w) * BW, (y + h) * BH], fill=rgba)
    return c


def cutaway(tech, lifts, set_, sel, tool="kit", stroke=0.0, tension=0.5, centre=0.5, band=0.26):
    random.seed(4)
    n = len(lifts)
    key_len = [0.14 + random.random() * 0.10 for _ in range(n)]
    step = (X1 - X0) / n
    pw = min(step * 0.46, 0.05)
    c = Image.new("RGBA", (BW, BH), (0, 0, 0, 255))
    c = place(c, "lp_housing_co", 0, 0, 1, 1)
    for i in range(n):
        cx = X0 + (i + 0.5) * step
        c = place(c, "lp_bore_ca", cx - pw * 0.65, CUT_TOP, pw * 1.3, CUT_KEYWAY - CUT_TOP)
    for i in range(n):
        cx = X0 + (i + 0.5) * step
        L = key_len[i]
        travel = CUT_KEYWAY - L - CUT_SHEAR
        key_bottom, driver_bottom = CUT_KEYWAY, CUT_SHEAR - 0.004
        if not set_[i]:
            key_bottom = CUT_KEYWAY - lifts[i] * travel
            driver_bottom = key_bottom - L
        driver_top = driver_bottom - DRIVER
        c = place(c, "lp_spring_ca", cx - pw / 2, CUT_TOP, pw, max(driver_top - CUT_TOP, 0.02))
        c = place(c, "lp_driverpin_ca", cx - pw / 2, driver_top, pw, DRIVER)
        c = place(c, "lp_keypin_ca", cx - pw / 2, key_bottom - L, pw, L)
    c = place(c, "lp_wrench_%s_ca" % tool, 0.03, CUT_KEYWAY - 0.12, 0.14, 0.26)
    if tech == "pins":
        px = X0 + (sel + 0.5) * step
        L = key_len[sel]
        tip = CUT_KEYWAY if set_[sel] else CUT_KEYWAY - lifts[sel] * (CUT_KEYWAY - L - CUT_SHEAR)
        c = place(c, "lp_pick_%s_ca" % tool, px - 0.02 * 0.70, tip - 0.42 * 0.16, 0.70, 0.16)
    else:
        swing = math.sin((0.35 - stroke) / 0.35 * math.pi) * (0.33 if stroke > 0 else 0)
        c = place(c, "lp_rake_ca", 0.63 - swing, CUT_KEYWAY - 0.52 * 0.16, 0.70, 0.16)
        c = fill(c, 0.02, 0.06, 0.26, 0.15, (5, 5, 4, 210))
        c = fill(c, 0.035, 0.155, 0.23, 0.012, (77, 77, 69, 255))
        c = fill(c, 0.035 + (centre - band / 2) * 0.23, 0.135, band * 0.23, 0.05, (77, 140, 64, 140))
        c = fill(c, 0.035 + tension * 0.23 - 0.002, 0.125, 0.004, 0.07, (242, 235, 204, 255))
        ImageDraw.Draw(c).text((0.035 * BW, 0.075 * BH), "TENSION", fill=(230, 225, 205, 255))
    return c


def face(turn, angle, strain, tool="clip"):
    c = Image.new("RGBA", (BW, BH), (0, 0, 0, 255))
    c = place(c, "lp_door_co", 0, 0, 1, 1)
    fh = 0.92; fw = fh / ASPECT
    c = place(c, "lp_face_ca", 0.5 - fw / 2, 0.04, fw, fh)
    ph = 0.50; pw = ph / ASPECT
    c = place(c, "lp_plug_%02d_ca" % min(18, max(0, round(turn / 5))), 0.5 - pw / 2, 0.5 - ph / 2, pw, ph)
    kh = 0.84; kw = kh / ASPECT
    tint = (209, 214, 224) if tool == "kit" else (247, 247, 255)
    c = place(c, "lp_dpick_%02d_ca" % min(30, max(0, round((angle + 90) / 6))), 0.5 - kw / 2, 0.5 - kh / 2, kw, kh, tint)
    c = fill(c, 0.72, 0.76, 0.26, 0.18, (5, 5, 4, 210))
    c = fill(c, 0.74, 0.87, 0.22, 0.03, (51, 51, 46, 255))
    c = fill(c, 0.74, 0.87, 0.22 * strain, 0.03, (int(184 + 59 * strain), int(148 - 87 * strain), 56, 255))
    ImageDraw.Draw(c).text((0.74 * BW, 0.79 * BH), "STRAIN", fill=(230, 225, 205, 255))
    return c


if __name__ == "__main__":
    frames = [
        cutaway("pins", [0, 0, 0.92, 0, 0.3], [True, False, False, True, False], 2, "kit"),
        cutaway("rake", [0.6, 0, 1.0, 0.2, 0.9], [False, True, False, False, False], 0, "clip", stroke=0.18, tension=0.55, centre=0.5),
        face(40, 18, 0.45, "clip"),
    ]
    sheet = Image.new("RGBA", (BW, BH * 3 + 40), (20, 20, 18, 255))
    for i, f in enumerate(frames):
        sheet.paste(f, (0, i * (BH + 20)))
    path = os.path.join(OUT, "lockpick.png")
    sheet.convert("RGB").save(path)
    print(path)
