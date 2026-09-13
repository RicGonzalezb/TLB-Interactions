# -*- coding: utf-8 -*-
"""Composites the mine and tripwire boards the way fn_mineDraw and fn_tripDraw
lay them out, so they can be judged without launching Arma.

    python tools/preview_types.py    -> tools/.preview/types.png

Top two frames: a mine partly prodded and dug, then fully exposed.
Bottom two frames: a tripwire in grass, then traced with a branch.
"""
import os
import random

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PNG = os.path.join(ROOT, "tools", ".png")
OUT = os.path.join(ROOT, "tools", ".preview")
os.makedirs(OUT, exist_ok=True)

BW, BH = 1400, 452
ASPECT = BW / BH
cache = {}


def sprite(name):
    if name not in cache:
        cache[name] = Image.open(os.path.join(PNG, name + ".png")).convert("RGBA")
    return cache[name]


def place(canvas, name, box, tint=None, alpha=1.0):
    x, y, w, h = box
    s = sprite(name).resize((max(1, int(w * BW)), max(1, int(h * BH))), Image.BILINEAR)
    if tint or alpha < 1:
        r, g, b, a = s.split()
        if tint:
            r, g, b = (ch.point(lambda v, k=k: v * k // 255) for ch, k in zip((r, g, b), tint))
        if alpha < 1:
            a = a.point(lambda v: int(v * alpha))
        s = Image.merge("RGBA", (r, g, b, a))
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    layer.paste(s, (int(x * BW), int(y * BH)))
    return Image.alpha_composite(canvas, layer)


# --------------------------------------------------------------------------
def mine_frame(exposed):
    random.seed(5)
    cols, rows, cx, cy, at = 11, 4, 6, 1, False
    stones = [2, 14, 30, 38, 42]
    gx, gy, cw, ch = 0.02, 0.05, 0.96 / cols, 0.90 / rows

    def cell(i):
        return (gx + (i % cols) * cw, gy + (i // cols) * ch, cw, ch)

    rim = [(cy + dr) * cols + cx + dc for dr in (-1, 0, 1) for dc in (-1, 0, 1) if (dr, dc) != (0, 0)]
    plate = cy * cols + cx
    dug = set(rim + [plate]) if exposed else {rim[0], rim[3]}
    probed = {i: 2 for i in rim[:5]}
    probed.update({4: 0, 5: 0, 16: 0, 14: 1})

    c = Image.new("RGBA", (BW, BH), (0, 0, 0, 255))
    c = place(c, "ground_co", (0, 0, 1, 1))
    for k, i in enumerate(stones):
        rx, ry, rw, rh = cell(i)
        s = min(rw, rh / ASPECT) * 0.7
        c = place(c, "stone_%s_ca" % "ab"[k % 2], (rx + (rw - s) / 2, ry + (rh - s * ASPECT) / 2, s, s * ASPECT))

    mx, my = gx + (cx + 0.5) * cw, gy + (cy + 0.5) * ch
    ms = min(3 * cw, 3 * ch / ASPECT) * 0.92
    c = place(c, "mine_at_ca" if at else "mine_ap_ca", (mx - ms / 2, my - ms * ASPECT / 2, ms, ms * ASPECT))
    if exposed:
        hole = mx + ms * (0.079 if at else 0.058)
        ps = ms * 0.20
        c = place(c, "pin_ca", (hole - ps * 0.30, my - ps * ASPECT / 2, ps, ps * ASPECT), tint=(224, 224, 214), alpha=0.6)

    for i in range(cols * rows):
        if i in dug:
            continue
        rx, ry, rw, rh = cell(i)
        k = 1.35 + ((i * 53) % 17) / 17 * 0.35
        ox = (((i * 31) % 13) / 13 - 0.5) * 0.30 * rw
        oy = (((i * 71) % 11) / 11 - 0.5) * 0.30 * rh
        c = place(c, "dirt_%s_ca" % "abcd"[(i * 7) % 4],
                  (rx + rw * (1 - k) / 2 + ox, ry + rh * (1 - k * 1.05) / 2 + oy, rw * k, rh * k * 1.05))
    tints = [(237, 235, 219), (133, 133, 128), (235, 56, 41)]
    for i, result in probed.items():
        if i in dug:
            continue
        rx, ry, rw, rh = cell(i)
        fw = rw * 0.26
        fh = fw * ASPECT * 2
        c = place(c, "flag_ca", (rx + rw * 0.55, ry + rh * 0.5 - fh * 0.85, fw, fh), tint=tints[result])
    return c


# --------------------------------------------------------------------------
def trip_frame(traced):
    random.seed(11)
    left, wire_y = True, 0.46
    anchor_x, fuze_x = 0.09, 0.86
    fuzes = [(fuze_x, wire_y)]
    jx, bx, by = 0.44, 0.66, 0.16
    fuzes.append((bx, by))

    tufts = []
    for t in range(10):
        tufts.append((0.09 + (0.86 - 0.09) * t / 9, wire_y + random.uniform(-0.04, 0.04), 0.11 + random.random() * 0.035,
                      random.randrange(3), True))
    for t in range(1, 4):
        tufts.append((jx + (bx - jx) * t / 3, wire_y + (by - wire_y) * t / 3, 0.12, random.randrange(3), True))
    for _ in range(10):
        tufts.append((0.04 + random.random() * 0.92, 0.08 + random.random() * 0.84, 0.12, random.randrange(3), False))

    steel = (199, 199, 189)
    c = Image.new("RGBA", (BW, BH), (0, 0, 0, 255))
    c = place(c, "ground_co", (0, 0, 1, 1))
    c = place(c, "tripwire_ca", (anchor_x, wire_y - 0.10 * 30 / 64, fuze_x - anchor_x, 0.10), tint=steel)
    up = by < wire_y
    end_k = 20 / 256 if up else 236 / 256
    h = abs(by - wire_y) / abs(end_k - 0.5)
    c = place(c, "tripbranch_%s_ca" % ("up" if up else "dn"), (jx, wire_y - 0.5 * h, bx - jx, h), tint=steel)

    sh = 0.36
    sw = sh / (2 * ASPECT)
    c = place(c, "stake_ca", (anchor_x - sw / 2, wire_y - 0.24 * sh, sw, sh))

    fs = 0.34
    fw = fs / ASPECT
    for k, (dx, dy) in enumerate(fuzes):
        rx, ry = dx - 0.22 * fw, dy - 0.19 * fs
        c = place(c, "tripfuze_ca", (rx, ry, fw, fs), tint=(255, 219, 133) if (traced and k == 1) else None)
        if traced and k == 0:
            pw = fw * 0.28
            c = place(c, "pin_ca", (rx + 0.50 * fw - pw * 0.3, ry + 0.18 * fs - pw * ASPECT / 2, pw, pw * ASPECT),
                      tint=(224, 224, 214))

    for tx, ty, size, v, on_path in tufts:
        if traced and on_path:
            continue
        hh = size * ASPECT
        c = place(c, "grass_%s_ca" % "abc"[v], (tx - size / 2, ty - hh * 0.62, size, hh))
    return c


if __name__ == "__main__":
    frames = [mine_frame(False), mine_frame(True), trip_frame(False), trip_frame(True)]
    sheet = Image.new("RGBA", (BW, BH * 4 + 60), (20, 20, 18, 255))
    for i, f in enumerate(frames):
        sheet.paste(f, (0, i * (BH + 20)))
    path = os.path.join(OUT, "types.png")
    sheet.convert("RGB").save(path)
    print(path)
