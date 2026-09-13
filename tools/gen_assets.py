# -*- coding: utf-8 -*-
"""Generates every texture the defusal board uses, then converts them to PAA.

    python tools/gen_assets.py

Needs Pillow. Conversion uses Arma 3 Tools' ImageToPAA.exe when it can find
it; without it the PNGs are still written to tools/.png so they can be
converted by hand. ImageToPAA only accepts power-of-two sizes, so every canvas
here is one.

Naming follows Arma convention: _co is opaque colour, _ca is colour with alpha.
Sprites that the engine tints (cables, tags, plates) are authored greyscale,
because the engine multiplies a texture by colorText - luminance in the file
becomes shading on whatever colour the script asks for.

A note on restraint: detail here is kept low-contrast on purpose. Every bright
scratch or high-contrast noise field reads as clutter once the sprite is
shrunk onto a board a few hundred pixels tall.
"""
import math
import os
import random
import shutil
import subprocess

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PNG = os.path.join(ROOT, "tools", ".png")
PAA = os.path.join(ROOT, "addons", "defusal", "data")
SS = 3

random.seed(20260913)
os.makedirs(PNG, exist_ok=True)
os.makedirs(PAA, exist_ok=True)

written = []


def save(img, name):
    img.save(os.path.join(PNG, name + ".png"))
    written.append((name, img.size))


# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------
def noise(size, scale, sigma=60):
    """Soft value noise: coarse random field, upscaled smoothly."""
    w, h = size
    return Image.effect_noise((max(2, w // scale), max(2, h // scale)), sigma).resize(size, Image.BICUBIC)


def grain(size, sigma=40):
    return Image.effect_noise(size, sigma)


def tint(gray, rgb):
    """Map a greyscale image onto a colour, 128 grey = the colour itself."""
    lut = lambda c: [max(0, min(255, int(c * v / 128))) for v in range(256)]
    return Image.merge("RGB", tuple(gray.point(lut(c)) for c in rgb))


def blend_multiply(base, gray, strength):
    """Darken/lighten an RGB image by a greyscale field centred on 128."""
    g = gray.point(lambda v: int(128 + (v - 128) * strength))
    return ImageChops.multiply(base, Image.merge("RGB", (g, g, g)).point(lambda v: min(255, v * 2)))


def vertical_shade(size, stops):
    """Luminance ramp along the image's long axis, for cylinders and bevels."""
    w, h = size
    length = h if w == 1 else w
    ramp = []
    for i in range(length):
        t = i / max(1, length - 1)
        for (t0, l0), (t1, l1) in zip(stops, stops[1:]):
            if t0 <= t <= t1:
                ramp.append(int(l0 + (l1 - l0) * (t - t0) / max(1e-6, t1 - t0)))
                break
    img = Image.new("L", size)
    img.putdata(ramp)
    return img


def scratch_layer(size, box, count, rgba, width, length=(10, 45)):
    """Scratches on their own layer, so they blend instead of overwriting."""
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x0, y0, x1, y1 = box
    for _ in range(count):
        x, y = random.uniform(x0, x1), random.uniform(y0, y1)
        ang = random.uniform(-0.35, 0.35) + random.choice([0, math.pi])
        ln = random.uniform(*length) * SS
        d.line([(x, y), (x + math.cos(ang) * ln, y + math.sin(ang) * ln)], fill=rgba, width=width)
    return layer


def smudges(size, count, colour, radius, alpha):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    w, h = size
    for _ in range(count):
        r = random.uniform(*radius)
        x, y = random.uniform(0, w), random.uniform(0, h)
        d.ellipse([x - r, y - r * random.uniform(0.4, 1.0), x + r, y + r],
                  fill=colour + (int(alpha * random.uniform(0.5, 1.0)),))
    return layer.filter(ImageFilter.GaussianBlur(radius[1] * 0.45))


def over(base, *layers):
    img = base.convert("RGBA")
    for layer in layers:
        img = Image.alpha_composite(img, layer)
    return img


def down(img, size):
    return img.resize(size, Image.LANCZOS)


# --------------------------------------------------------------------------
# ground: dry, cracked soil with fine gravel
# --------------------------------------------------------------------------
def make_ground():
    size = (1024, 256)
    big = (size[0] * 2, size[1] * 2)
    field = ImageChops.add(noise(big, 40, 55), noise(big, 9, 26), scale=2.0)
    base = blend_multiply(tint(field, (128, 112, 90)), grain(big, 40), 0.25)

    d = ImageDraw.Draw(base)
    for _ in range(18):
        x, y = random.uniform(0, big[0]), random.uniform(0, big[1])
        pts = [(x, y)]
        for _ in range(random.randint(4, 8)):
            x += random.uniform(-40, 40)
            y += random.uniform(-40, 40)
            pts.append((x, y))
        d.line(pts, fill=(92, 80, 62), width=random.choice([1, 1, 2]))

    for _ in range(160):
        x, y = random.uniform(0, big[0]), random.uniform(0, big[1])
        r = random.uniform(1.2, 4.0)
        tone = random.randint(108, 150)
        d.ellipse([x - r + 1, y - r * 0.7 + 1.5, x + r + 1, y + r * 0.7 + 1.5], fill=(80, 70, 56))
        d.ellipse([x - r, y - r * 0.7, x + r, y + r * 0.7], fill=(tone, tone - 8, tone - 20))

    img = over(base, smudges(big, 12, (30, 24, 16), (60, 160), 70))
    save(down(img.convert("RGB"), size), "ground_co")


# --------------------------------------------------------------------------
# shell: weathered artillery projectile lying on its side, nose to the right
# --------------------------------------------------------------------------
def make_shell():
    size = (1024, 256)
    W, H = size[0] * SS, size[1] * SS
    top, bot = 38 * SS, 218 * SS
    body_x0, nose_x0, tip_x = 30 * SS, 760 * SS, 1010 * SS

    shape = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(shape)
    d.rounded_rectangle([body_x0, top, nose_x0 + 20 * SS, bot], radius=14 * SS, fill=255)
    mid = (top + bot) / 2
    radius = (bot - top) / 2
    nose = []
    for i in range(41):
        t = i / 40
        nose.append((nose_x0 + (tip_x - nose_x0) * t, mid - (radius * (1 - t ** 1.9) + 22 * SS * t)))
    nose += [(x, 2 * mid - y) for (x, y) in reversed(nose)]
    d.polygon(nose, fill=255)
    shape = shape.filter(ImageFilter.GaussianBlur(0.8 * SS))

    shade = vertical_shade((1, H), [(0, 40), (top / H, 60), ((top + (bot - top) * 0.28) / H, 200),
                                    ((top + (bot - top) * 0.55) / H, 140), (bot / H, 45), (1, 40)])
    shade = shade.resize((W, H))
    body = blend_multiply(tint(shade, (82, 90, 52)), noise((W, H), 30, 40), 0.35)
    body = blend_multiply(body, grain((W, H), 30), 0.15)

    d = ImageDraw.Draw(body)
    d.rectangle([600 * SS, 0, 640 * SS, H], fill=(160, 138, 58))          # yellow HE band
    d.rectangle([118 * SS, 0, 150 * SS, H], fill=(140, 98, 60))           # copper driving band
    d.rectangle([118 * SS, 0, 122 * SS, H], fill=(96, 66, 40))
    d.ellipse([990 * SS, mid - 16 * SS, 1022 * SS, mid + 16 * SS], fill=(26, 26, 22))
    body = ImageChops.multiply(body, Image.merge("RGB", [shade.point(lambda v: min(255, v + 70))] * 3))

    box = (body_x0, top, tip_x, bot)
    img = over(body,
               scratch_layer((W, H), box, 70, (170, 168, 140, 55), SS),
               scratch_layer((W, H), box, 40, (30, 32, 20, 70), SS),
               smudges((W, H), 36, (98, 54, 26), (8 * SS, 40 * SS), 130),
               smudges((W, H), 24, (92, 78, 56), (30 * SS, 90 * SS), 150))
    img.putalpha(shape)
    save(down(img, size), "shell_ca")


def tape_band(size, x0, x1, y0, y1, jitter=4):
    """A horizontal band of tape with ragged, torn top and bottom edges."""
    xs = [x0 + i * (x1 - x0) / 12 for i in range(13)]
    topedge = [(x * SS, (y0 + random.uniform(-jitter, jitter)) * SS) for x in xs]
    bottom = [(x * SS, (y1 + random.uniform(-jitter, jitter)) * SS) for x in reversed(xs)]
    band = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(band).polygon(topedge + bottom, fill=(24, 24, 22, 245))
    wrinkles = scratch_layer(size, (x0 * SS, y0 * SS, x1 * SS, y1 * SS), 10, (90, 90, 84, 45), SS)
    wrinkles.putalpha(ImageChops.multiply(wrinkles.split()[3], band.split()[3]))
    return Image.alpha_composite(band, wrinkles)


# --------------------------------------------------------------------------
# trigger pack: phone and 9V battery bound with tape
# --------------------------------------------------------------------------
def make_pack():
    size = (256, 512)
    W, H = size[0] * SS, size[1] * SS
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([28 * SS, 30 * SS, 236 * SS, 500 * SS], radius=20 * SS,
                                             fill=(0, 0, 0, 150))
    img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(10 * SS)))

    phone = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(phone)
    d.rounded_rectangle([36 * SS, 18 * SS, 214 * SS, 300 * SS], radius=26 * SS, fill=(150, 144, 124, 255))
    d.rounded_rectangle([36 * SS, 18 * SS, 214 * SS, 300 * SS], radius=26 * SS, outline=(64, 60, 52, 255),
                        width=3 * SS)
    d.rounded_rectangle([62 * SS, 44 * SS, 188 * SS, 120 * SS], radius=8 * SS, fill=(62, 76, 64, 255))
    for row in range(4):
        for col in range(3):
            x, y = 72 * SS + col * 40 * SS, 150 * SS + row * 34 * SS
            d.rounded_rectangle([x, y, x + 28 * SS, y + 20 * SS], radius=5 * SS, fill=(110, 104, 90, 255))
    d.rectangle([196 * SS, 2 * SS, 206 * SS, 30 * SS], fill=(40, 40, 36, 255))
    img = Image.alpha_composite(img, over(phone, smudges((W, H), 14, (70, 58, 40), (10 * SS, 40 * SS), 110)))

    batt = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(batt)
    d.rounded_rectangle([54 * SS, 318 * SS, 196 * SS, 492 * SS], radius=8 * SS, fill=(28, 28, 26, 255))
    d.rectangle([54 * SS, 380 * SS, 196 * SS, 432 * SS], fill=(132, 104, 38, 255))
    d.rectangle([84 * SS, 304 * SS, 108 * SS, 320 * SS], fill=(150, 150, 140, 255))
    d.rectangle([142 * SS, 304 * SS, 166 * SS, 320 * SS], fill=(150, 150, 140, 255))
    img = Image.alpha_composite(img, batt)

    for y0, y1 in ((96, 150), (262, 330), (440, 480)):
        img = Image.alpha_composite(img, tape_band((W, H), 24, 232, y0, y1))

    img = Image.alpha_composite(img, smudges((W, H), 18, (96, 82, 60), (12 * SS, 50 * SS), 90))
    save(down(img, size), "pack_ca")


# --------------------------------------------------------------------------
# junction: tape-bound booster with a detonator lead
# --------------------------------------------------------------------------
def make_junction():
    size = (256, 512)
    W, H = size[0] * SS, size[1] * SS
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([34 * SS, 34 * SS, 236 * SS, 500 * SS], radius=30 * SS,
                                             fill=(0, 0, 0, 160))
    img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(10 * SS)))

    shade = vertical_shade((W, 1), [(0, 45), (0.3, 140), (0.55, 100), (1, 40)]).resize((W, H))
    body = blend_multiply(tint(shade, (40, 40, 37)), grain((W, H), 40), 0.25)
    part = over(body, scratch_layer((W, H), (0, 0, W, H), 12, (90, 90, 84, 50), SS, (30, 120)))
    blob = Image.new("L", (W, H), 0)
    ImageDraw.Draw(blob).rounded_rectangle([30 * SS, 20 * SS, 228 * SS, 492 * SS], radius=34 * SS, fill=255)
    part.putalpha(blob)
    img = Image.alpha_composite(img, part)

    det = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(det)
    d.rounded_rectangle([150 * SS, 0, 186 * SS, 70 * SS], radius=10 * SS, fill=(160, 156, 140, 255))
    d.rectangle([150 * SS, 44 * SS, 186 * SS, 54 * SS], fill=(104, 100, 90, 255))
    img = Image.alpha_composite(img, det)
    img = Image.alpha_composite(img, smudges((W, H), 20, (92, 80, 60), (14 * SS, 60 * SS), 100))
    save(down(img, size), "junction_ca")


# --------------------------------------------------------------------------
# duct tape strip, vertical, torn at both ends
# --------------------------------------------------------------------------
def make_tape(name, seed):
    random.seed(seed)
    size = (128, 512)
    W, H = size[0] * SS, size[1] * SS

    shape = Image.new("L", (W, H), 0)
    pts = [(14 * SS, 18 * SS)]
    pts += [(14 * SS + i * 12.5 * SS, random.uniform(2, 30) * SS) for i in range(1, 9)]
    pts += [(114 * SS, 18 * SS), (114 * SS, 494 * SS)]
    pts += [(14 * SS + i * 12.5 * SS, (512 - random.uniform(2, 30)) * SS) for i in range(8, 0, -1)]
    pts += [(14 * SS, 494 * SS)]
    ImageDraw.Draw(shape).polygon(pts, fill=255)

    shade = vertical_shade((W, 1), [(0, 70), (0.2, 118), (0.45, 142), (0.8, 100), (1, 62)]).resize((W, H))
    tape = blend_multiply(tint(shade, (34, 34, 32)), noise((W, H), 14, 36), 0.25)
    img = over(tape,
               scratch_layer((W, H), (0, 0, W, H), 10, (96, 96, 90, 55), SS, (30, 120)),
               scratch_layer((W, H), (0, 0, W, H), 8, (8, 8, 8, 70), SS, (30, 120)),
               smudges((W, H), 18, (120, 104, 78), (8 * SS, 34 * SS), 120))
    img.putalpha(shape)
    save(down(img, size), name)


# --------------------------------------------------------------------------
# soil clumps
# --------------------------------------------------------------------------
def make_dirt(name, seed):
    random.seed(seed)
    size = (256, 256)
    W, H = size[0] * SS, size[1] * SS

    shape = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(shape)
    cx, cy = W / 2, H / 2
    for _ in range(14):
        r = random.uniform(30, 70) * SS
        x = cx + random.uniform(-58, 58) * SS
        y = cy + random.uniform(-44, 50) * SS
        d.ellipse([x - r, y - r * 0.8, x + r, y + r * 0.8], fill=255)
    shape = shape.filter(ImageFilter.GaussianBlur(7 * SS)).point(lambda v: min(255, int(v * 1.7)))

    # Mound lighting from a blurred height field: lit on the top-left slope,
    # shadowed on the bottom-right, soft rather than cut out.
    height = shape.filter(ImageFilter.GaussianBlur(18 * SS))
    shifted = ImageChops.offset(height, 9 * SS, 11 * SS)
    lit = ImageChops.subtract(height, shifted).point(lambda v: min(255, int(v * 1.4)))
    shaded = ImageChops.subtract(shifted, height).point(lambda v: min(255, int(v * 1.8)))

    field = ImageChops.add(noise((W, H), 26, 34), grain((W, H), 26), scale=2.0)
    soil = tint(field, (116, 98, 74)).convert("RGBA")
    light = Image.new("RGBA", (W, H), (210, 188, 150, 0))
    light.putalpha(lit)
    dark = Image.new("RGBA", (W, H), (40, 32, 22, 0))
    dark.putalpha(shaded)
    img = over(soil, light, dark)

    d = ImageDraw.Draw(img)
    for _ in range(26):
        x, y = random.uniform(0, W), random.uniform(0, H)
        r = random.uniform(2, 6) * SS
        tone = random.randint(100, 140)
        d.ellipse([x - r + SS, y - r * 0.7 + SS, x + r + SS, y + r * 0.7 + SS], fill=(62, 52, 40, 255))
        d.ellipse([x - r, y - r * 0.7, x + r, y + r * 0.7], fill=(tone, tone - 10, tone - 24, 255))

    img.putalpha(shape)
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    shadow.putalpha(ImageChops.offset(shape, 8 * SS, 12 * SS).filter(ImageFilter.GaussianBlur(10 * SS))
                    .point(lambda v: int(v * 0.5)))
    save(down(Image.alpha_composite(shadow, img), size), name)


# --------------------------------------------------------------------------
# UI chrome
# --------------------------------------------------------------------------
def make_panel():
    size = (1024, 512)
    big = (size[0] * 2, size[1] * 2)
    field = ImageChops.add(noise(big, 60, 36), grain(big, 24), scale=2.0)
    img = over(tint(field, (48, 50, 40)),
               scratch_layer(big, (0, 0, big[0], big[1]), 120, (96, 98, 82, 60), 2),
               scratch_layer(big, (0, 0, big[0], big[1]), 60, (16, 17, 12, 80), 2),
               smudges(big, 30, (14, 14, 10), (80, 260), 110))

    vig = Image.new("L", big, 0)
    ImageDraw.Draw(vig).rectangle([40, 40, big[0] - 40, big[1] - 40], fill=255)
    img = Image.composite(img, Image.new("RGBA", big, (6, 6, 4, 255)), vig.filter(ImageFilter.GaussianBlur(90)))

    d = ImageDraw.Draw(img)
    for (x, y) in ((28, 28), (big[0] - 28, 28), (28, big[1] - 28), (big[0] - 28, big[1] - 28)):
        d.ellipse([x - 11, y - 11, x + 11, y + 11], fill=(20, 20, 16))
        d.ellipse([x - 8, y - 9, x + 8, y + 7], fill=(90, 90, 80))
    save(down(img.convert("RGB"), size), "panel_co")


def make_plate():
    size = (256, 64)
    big = (size[0] * 4, size[1] * 4)
    shade = vertical_shade((1, big[1]), [(0, 190), (0.12, 150), (0.5, 128), (0.9, 100), (1, 60)]).resize(big)
    plate = blend_multiply(Image.merge("RGB", (shade, shade, shade)), noise(big, 16, 36), 0.25)
    img = over(plate,
               scratch_layer(big, (0, 0, big[0], big[1]), 30, (200, 200, 190, 70), 2),
               scratch_layer(big, (0, 0, big[0], big[1]), 20, (50, 50, 46, 80), 2),
               smudges(big, 10, (30, 26, 18), (20, 80), 100))
    save(down(img.convert("RGB"), size), "plate_co")


def make_lcd():
    size = (512, 64)
    big = (size[0] * 4, size[1] * 4)
    shade = vertical_shade((1, big[1]), [(0, 110), (0.5, 132), (1, 112)]).resize(big)
    lcd = blend_multiply(tint(shade, (146, 156, 124)), grain(big, 12), 0.12)
    d = ImageDraw.Draw(lcd)
    d.rectangle([0, 0, big[0] - 1, big[1] - 1], outline=(38, 40, 32), width=14)
    d.rectangle([14, 14, big[0] - 15, 24], fill=(96, 102, 80))
    save(down(lcd, size), "lcd_co")


def make_tag():
    size = (128, 64)
    big = (size[0] * 4, size[1] * 4)
    card = Image.new("L", big, 0)
    ImageDraw.Draw(card).polygon([(40, 12), (500, 12), (500, 244), (40, 244), (6, 128)], fill=255)
    field = ImageChops.add(noise(big, 20, 26), grain(big, 24), scale=2.0)
    paper = over(Image.merge("RGB", [field.point(lambda v: min(255, 150 + v // 3))] * 3),
                 smudges(big, 12, (60, 50, 34), (10, 50), 100))
    paper.putalpha(card)
    d = ImageDraw.Draw(paper)
    d.ellipse([34, 110, 62, 146], fill=(0, 0, 0, 0))
    d.ellipse([38, 114, 58, 142], outline=(80, 80, 72, 255), width=4)
    save(down(paper, size), "tag_ca")


# --------------------------------------------------------------------------
# cables: greyscale, twisted, tinted in engine
# --------------------------------------------------------------------------
CW, ROW, CORE = 1024, 128, 18
CPAD = {0: 64, 1: 64, 2: 128}      # must match _padFactor in fn_drawBoard.sqf


def bezier(p0, p1, p2, p3, steps=480):
    out = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        a, b, c, e = u * u * u, 3 * u * u * t, 3 * u * t * t, t * t * t
        out.append((a * p0[0] + b * p1[0] + c * p2[0] + e * p3[0],
                    a * p0[1] + b * p1[1] + c * p2[1] + e * p3[1]))
    return out


def normals(pts):
    out = []
    for i in range(len(pts)):
        j, k = min(i + 1, len(pts) - 1), max(i - 1, 0)
        dx, dy = pts[j][0] - pts[k][0], pts[j][1] - pts[k][1]
        n = math.hypot(dx, dy) or 1.0
        out.append((-dy / n, dx / n))
    return out


def ribbon(size, pts, nrm, width, lum, alpha, offset=(0, 0), blur=0):
    """Offset-polygon stroke: clean edges where a thick polyline would notch."""
    half = width / 2
    left = [(x + nx * half + offset[0], y + ny * half + offset[1]) for (x, y), (nx, ny) in zip(pts, nrm)]
    right = [(x - nx * half + offset[0], y - ny * half + offset[1]) for (x, y), (nx, ny) in zip(pts, nrm)]
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).polygon(left + right[::-1], fill=(lum, lum, lum, alpha))
    return layer.filter(ImageFilter.GaussianBlur(blur)) if blur else layer


def make_cable(delta, variant, sag_a, sag_b):
    pad = CPAD[abs(delta)]
    h = abs(delta) * ROW + 2 * pad
    S = 4
    size = (CW * S, h * S)
    y0 = (pad + max(0, -delta) * ROW) * S
    y1 = (pad + max(0, delta) * ROW) * S
    pts = bezier((0, y0), (CW * S * 0.32, y0 + sag_a * S), (CW * S * 0.68, y1 + sag_b * S), (CW * S, y1))
    nrm = normals(pts)

    img = Image.new("RGBA", size, (0, 0, 0, 0))
    img = Image.alpha_composite(img, ribbon(size, pts, nrm, (CORE + 10) * S, 8, 110, (2 * S, 5 * S), 6 * S))
    img = Image.alpha_composite(img, ribbon(size, pts, nrm, (CORE + 5) * S, 34, 255))
    core = ribbon(size, pts, nrm, CORE * S, 176, 255)
    img = Image.alpha_composite(img, core)

    # Twist: faint diagonal lays masked to the core. Kept subtle - at full
    # strength they read as a barber pole rather than as a twisted conductor.
    lays = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lays)
    acc, step = 0.0, 13 * S
    for i in range(1, len(pts)):
        acc += math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1])
        if acc >= step:
            acc = 0.0
            (x, y), (nx, ny) = pts[i], nrm[i]
            tx, ty = ny, -nx
            hw = CORE * S * 0.55
            d.line([(x + nx * hw - tx * hw * 0.6, y + ny * hw - ty * hw * 0.6),
                    (x - nx * hw + tx * hw * 0.6, y - ny * hw + ty * hw * 0.6)],
                   fill=(118, 118, 118, 70), width=int(2.5 * S))
    lays.putalpha(ImageChops.multiply(lays.split()[3], core.split()[3]))
    img = Image.alpha_composite(img, lays)

    img = Image.alpha_composite(img, ribbon(size, pts, nrm, CORE * 0.26 * S, 255, 140, (0, -3.0 * S), 0.6 * S))
    save(img.resize((CW, h), Image.LANCZOS),
         "cable_d%s%d_%s" % ("m" if delta < 0 else "p", abs(delta), variant))


CABLE_VARIANTS = {
    0: [("a", 26, 30), ("b", -22, -26)],
    1: [("a", 34, -18), ("b", -14, 30)],
    -1: [("a", -34, 18), ("b", 14, -30)],
    2: [("a", 40, -24), ("b", -18, 36)],
    -2: [("a", -40, 24), ("b", 18, -36)],
}


# --------------------------------------------------------------------------
# mines: top-down pressure mines, a stone, prod marker flags
# --------------------------------------------------------------------------
def radial(size, cx, cy, radius):
    """Greyscale radial ramp: 0 at (cx, cy), 255 at radius and beyond."""
    g = Image.radial_gradient("L")                  # 256x256, 0 centre -> 255 at r=128
    scale = radius / 128.0
    g = g.resize((int(256 * scale), int(256 * scale)), Image.BICUBIC)
    out = Image.new("L", size, 255)
    out.paste(g, (int(cx - g.width / 2), int(cy - g.height / 2)))
    return out


def make_mine(name, at):
    size = (256, 256)
    W, H = size[0] * SS, size[1] * SS
    cx, cy = W / 2, H / 2
    r = (116 if at else 98) * SS

    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse([cx - r + 8 * SS, cy - r + 12 * SS, cx + r + 8 * SS, cy + r + 12 * SS],
                                   fill=(0, 0, 0, 170))
    img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(9 * SS)))

    # Body lit from the top left: a radial ramp centred up and to the left.
    light = radial((W, H), cx - r * 0.35, cy - r * 0.35, r * 2.0).point(lambda v: 255 - v)
    body = tint(light.point(lambda v: 70 + v * 90 // 255), (64, 70, 42) if at else (78, 86, 50))
    body = blend_multiply(body, noise((W, H), 20, 36), 0.30)
    d = ImageDraw.Draw(body)
    for k in (0.93, 0.80, 0.67):
        rr = r * k
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], outline=(40, 44, 26), width=2 * SS)
    for i in range(16):
        a = i * math.pi / 8
        d.line([(cx + math.cos(a) * r * 0.82, cy + math.sin(a) * r * 0.82),
                (cx + math.cos(a) * r * 0.96, cy + math.sin(a) * r * 0.96)], fill=(44, 48, 28), width=3 * SS)
    if at:
        d.rounded_rectangle([cx - r * 0.18, cy - r * 1.02, cx + r * 0.18, cy - r * 0.84], radius=6 * SS,
                            fill=(52, 56, 34), outline=(30, 32, 20), width=2 * SS)

    # Pressure plate, fuze boss and the pin hole the whole procedure is aiming for.
    pr = r * (0.46 if at else 0.40)
    d.ellipse([cx - pr, cy - pr, cx + pr, cy + pr], fill=(98, 104, 66), outline=(36, 40, 24), width=3 * SS)
    for a in (0, math.pi / 2):
        d.line([(cx - math.cos(a) * pr * 0.8, cy - math.sin(a) * pr * 0.8),
                (cx + math.cos(a) * pr * 0.8, cy + math.sin(a) * pr * 0.8)], fill=(70, 76, 46), width=4 * SS)
    br = pr * 0.42
    d.ellipse([cx - br, cy - br, cx + br, cy + br], fill=(70, 70, 64), outline=(28, 28, 26), width=2 * SS)
    d.ellipse([cx + br * 0.9 - 7 * SS, cy - 7 * SS, cx + br * 0.9 + 7 * SS, cy + 7 * SS], fill=(150, 146, 120))
    d.ellipse([cx + br * 0.9 - 4 * SS, cy - 4 * SS, cx + br * 0.9 + 4 * SS, cy + 4 * SS], fill=(10, 10, 10))

    part = over(body,
                scratch_layer((W, H), (cx - r, cy - r, cx + r, cy + r), 40, (150, 150, 120, 50), SS),
                smudges((W, H), 26, (98, 80, 56), (10 * SS, 44 * SS), 150))
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    part.putalpha(mask.filter(ImageFilter.GaussianBlur(0.8 * SS)))
    img = Image.alpha_composite(img, part)
    save(down(img, size), name)


def make_stone(name, seed):
    random.seed(seed)
    size = (128, 128)
    W, H = size[0] * SS, size[1] * SS
    pts = []
    for i in range(11):
        a = i * 2 * math.pi / 11
        rr = random.uniform(34, 52) * SS
        pts.append((W / 2 + math.cos(a) * rr, H / 2 + math.sin(a) * rr * 0.8))
    shape = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shape).polygon(pts, fill=255)
    shape = shape.filter(ImageFilter.GaussianBlur(3 * SS))
    height = shape.filter(ImageFilter.GaussianBlur(12 * SS))
    lit = ImageChops.subtract(height, ImageChops.offset(height, 6 * SS, 8 * SS)).point(lambda v: min(255, v * 2))
    rock = tint(ImageChops.add(noise((W, H), 10, 40), grain((W, H), 30), scale=2.0), (118, 114, 104)).convert("RGBA")
    hi = Image.new("RGBA", (W, H), (220, 214, 196, 0))
    hi.putalpha(lit)
    rock = Image.alpha_composite(rock, hi)
    rock.putalpha(shape)
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    shadow.putalpha(ImageChops.offset(shape, 5 * SS, 8 * SS).filter(ImageFilter.GaussianBlur(6 * SS))
                    .point(lambda v: v // 2))
    save(down(Image.alpha_composite(shadow, rock), size), name)


def make_flag():
    """Prod marker: a wire stake with a small flag. Greyscale; tinted per result."""
    size = (64, 128)
    W, H = size[0] * 4, size[1] * 4
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([60, 470, 150, 500], fill=(0, 0, 0, 110))
    d.line([(100, 480), (100, 60)], fill=(70, 70, 70, 255), width=10)
    d.polygon([(104, 60), (236, 104), (104, 150)], fill=(235, 235, 235, 255))
    d.line([(104, 150), (236, 104)], fill=(150, 150, 150, 255), width=6)
    save(down(img, size), "flag_ca")


# --------------------------------------------------------------------------
# tripwires: grass, anchor stake, firing device, wire, branch, safety pin
# --------------------------------------------------------------------------
def make_grass(name, seed):
    random.seed(seed)
    size = (256, 256)
    W, H = size[0] * SS, size[1] * SS
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    base = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(base).ellipse([W * 0.18, H * 0.52, W * 0.82, H * 0.86], fill=(34, 30, 18, 150))
    img = Image.alpha_composite(img, base.filter(ImageFilter.GaussianBlur(14 * SS)))
    d = ImageDraw.Draw(img)
    for _ in range(170):
        x0 = W / 2 + random.gauss(0, 34) * SS
        y0 = H * 0.72 + random.gauss(0, 10) * SS
        ang = -math.pi / 2 + random.gauss(0, 0.55)
        ln = random.uniform(60, 115) * SS
        bend = random.uniform(-0.5, 0.5)
        pts = []
        for t in range(9):
            k = t / 8
            a = ang + bend * k * k
            pts.append((x0 + math.cos(a) * ln * k, y0 + math.sin(a) * ln * k))
        tone = random.randint(0, 60)
        colour = (118 + tone, 108 + tone, 62 + tone // 2, 255)
        d.line(pts, fill=colour, width=random.choice([2, 2, 3]) * SS, joint="curve")
    save(down(img, size), name)


def make_stake():
    size = (128, 256)
    W, H = size[0] * SS, size[1] * SS
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([W * 0.25, H * 0.86, W * 0.85, H * 0.97], fill=(0, 0, 0, 140))
    img = Image.alpha_composite(img, sh.filter(ImageFilter.GaussianBlur(6 * SS)))
    wood = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(wood)
    d.polygon([(W * 0.38, H * 0.10), (W * 0.62, H * 0.10), (W * 0.57, H * 0.90), (W * 0.50, H * 0.96),
               (W * 0.43, H * 0.90)], fill=(118, 90, 58, 255))
    for i in range(7):
        x = W * (0.41 + i * 0.03)
        d.line([(x, H * 0.12), (x + random.uniform(-4, 4) * SS, H * 0.88)], fill=(84, 62, 38, 160), width=SS)
    d.polygon([(W * 0.38, H * 0.10), (W * 0.62, H * 0.10), (W * 0.60, H * 0.16), (W * 0.40, H * 0.16)],
              fill=(150, 118, 80, 255))
    d.ellipse([W * 0.34, H * 0.18, W * 0.66, H * 0.30], outline=(150, 150, 140, 255), width=3 * SS)
    img = Image.alpha_composite(img, over(wood, smudges((W, H), 10, (60, 48, 30), (6 * SS, 20 * SS), 110)))
    save(down(img, size), "stake_ca")


def make_tripfuze():
    size = (256, 256)
    W, H = size[0] * SS, size[1] * SS
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([W * 0.20, H * 0.70, W * 0.86, H * 0.92], fill=(0, 0, 0, 160))
    img = Image.alpha_composite(img, sh.filter(ImageFilter.GaussianBlur(10 * SS)))

    stake = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(stake).polygon([(W * 0.46, H * 0.55), (W * 0.54, H * 0.55), (W * 0.52, H * 0.86),
                                   (W * 0.48, H * 0.86)], fill=(108, 82, 52, 255))
    img = Image.alpha_composite(img, stake)

    # Grenade-type body, olive, lit from the top left.
    body_box = (W * 0.30, H * 0.22, W * 0.70, H * 0.66)
    shade = vertical_shade((W, 1), [(0, 50), (0.35, 190), (0.6, 130), (1, 40)]).resize((W, H))
    body = blend_multiply(tint(shade, (80, 88, 50)), noise((W, H), 12, 40), 0.3)
    d = ImageDraw.Draw(body)
    for i in range(5):
        y = H * (0.28 + i * 0.08)
        d.line([(0, y), (W, y)], fill=(46, 50, 28), width=2 * SS)
    part = over(body, smudges((W, H), 12, (96, 80, 56), (8 * SS, 30 * SS), 130))
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).ellipse(body_box, fill=255)
    part.putalpha(mask)
    img = Image.alpha_composite(img, part)

    top = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(top)
    d.rounded_rectangle([W * 0.42, H * 0.10, W * 0.58, H * 0.26], radius=6 * SS, fill=(128, 126, 112, 255),
                        outline=(50, 50, 46, 255), width=2 * SS)
    d.polygon([(W * 0.58, H * 0.14), (W * 0.66, H * 0.16), (W * 0.64, H * 0.56), (W * 0.60, H * 0.56)],
              fill=(112, 110, 98, 255))                                              # striker lever
    d.ellipse([W * 0.14, H * 0.12, W * 0.30, H * 0.26], outline=(170, 168, 150, 255), width=3 * SS)  # pull ring
    d.line([(W * 0.29, H * 0.19), (W * 0.42, H * 0.18)], fill=(170, 168, 150, 255), width=2 * SS)
    d.ellipse([W * 0.47, H * 0.155, W * 0.53, H * 0.205], fill=(12, 12, 12, 255))    # pin hole
    img = Image.alpha_composite(img, top)
    save(down(img, size), "tripfuze_ca")


def wire_sprite(size, p0, p1, sag, name):
    """A thin steel tripwire, greyscale so it can be tinted, drawn as a ribbon."""
    S = 4
    W, H = size[0] * S, size[1] * S
    a = (p0[0] * S, p0[1] * S)
    b = (p1[0] * S, p1[1] * S)
    mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 + sag * S)
    pts = bezier(a, (a[0] + (mid[0] - a[0]) * 0.9, mid[1]), (b[0] - (b[0] - mid[0]) * 0.9, mid[1]), b, 300)
    nrm = normals(pts)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    img = Image.alpha_composite(img, ribbon((W, H), pts, nrm, 5 * S, 0, 90, (1.5 * S, 4 * S), 2.5 * S))
    img = Image.alpha_composite(img, ribbon((W, H), pts, nrm, 3.2 * S, 60, 255))
    img = Image.alpha_composite(img, ribbon((W, H), pts, nrm, 1.3 * S, 235, 220, (0, -0.6 * S)))
    save(img.resize(size, Image.LANCZOS), name)


def make_pin():
    """Safety pin seated in a fuze: a split pin with its ring. Greyscale."""
    size = (64, 64)
    W, H = size[0] * 4, size[1] * 4
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([28, 60, 148, 180], outline=(40, 40, 40, 255), width=22)
    d.ellipse([28, 60, 148, 180], outline=(220, 220, 220, 255), width=14)
    d.rectangle([140, 112, 244, 128], fill=(40, 40, 40, 255))
    d.rectangle([142, 114, 240, 124], fill=(225, 225, 225, 255))
    save(down(img, size), "pin_ca")


# --------------------------------------------------------------------------
def convert():
    candidates = [
        r"E:\SteamLibrary\steamapps\common\Arma 3 Tools\ImageToPAA\ImageToPAA.exe",
        r"C:\Program Files (x86)\Steam\steamapps\common\Arma 3 Tools\ImageToPAA\ImageToPAA.exe",
        r"D:\SteamLibrary\steamapps\common\Arma 3 Tools\ImageToPAA\ImageToPAA.exe",
    ]
    tool = next((c for c in candidates if os.path.exists(c)), shutil.which("ImageToPAA"))
    if not tool:
        print("ImageToPAA not found - PNGs left in", PNG)
        return
    failed = []
    for name, _ in written:
        src = os.path.join(PNG, name + ".png")
        dst = os.path.join(PAA, name + ".paa")
        if os.path.exists(dst):
            os.remove(dst)
        subprocess.run([tool, src, dst], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if not os.path.exists(dst):
            failed.append(name)
    print("converted %d/%d to PAA%s" % (len(written) - len(failed), len(written),
                                        "" if not failed else " - FAILED: " + ", ".join(failed)))


if __name__ == "__main__":
    make_ground()
    make_shell()
    make_pack()
    make_junction()
    make_tape("tape_a_ca", 11)
    make_tape("tape_b_ca", 23)
    for i, n in enumerate("abcd"):
        make_dirt("dirt_%s_ca" % n, 100 + i * 7)
    make_panel()
    make_plate()
    make_lcd()
    make_tag()
    for delta, vs in sorted(CABLE_VARIANTS.items()):
        for variant, sa, sb in vs:
            make_cable(delta, variant, sa, sb)

    make_mine("mine_ap_ca", False)
    make_mine("mine_at_ca", True)
    make_stone("stone_a_ca", 301)
    make_stone("stone_b_ca", 302)
    make_flag()
    for i, n in enumerate("abc"):
        make_grass("grass_%s_ca" % n, 400 + i * 13)
    make_stake()
    make_tripfuze()
    wire_sprite((1024, 64), (0, 30), (1024, 30), 10, "tripwire_ca")
    wire_sprite((512, 256), (0, 128), (512, 20), -10, "tripbranch_up_ca")
    wire_sprite((512, 256), (0, 128), (512, 236), 10, "tripbranch_dn_ca")
    make_pin()

    for name, (w, h) in written:
        pot = (w & (w - 1)) == 0 and (h & (h - 1)) == 0
        print("  %-18s %4dx%-4d %s" % (name, w, h, "" if pot else "NOT POWER OF TWO"))
    convert()
