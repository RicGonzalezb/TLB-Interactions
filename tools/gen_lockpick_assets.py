# -*- coding: utf-8 -*-
"""Generates the lockpicking textures and converts them to PAA.

    python tools/gen_lockpick_assets.py

Two views:

  cutaway  - side section through a pin-tumbler cylinder, used by the pin
             tumbler and rake techniques. Pins, springs and picks are separate
             sprites so the script can move them vertically and horizontally.
  face     - front view of a lock set in a wooden door, used by the sweet-spot
             technique. Arma's dialog UI cannot rotate controls (ctrlSetAngle
             silently does nothing on runtime-created controls), so the plug and
             the pick are pre-rendered as frames at fixed angles and swapped.

Frame steps below must match script_component.hpp in addons/lockpick:
PLUG_STEP 5 degrees (0..90, 19 frames), PICK_STEP 6 degrees (-90..90, 31 frames).
"""
import math
import os
import random
import shutil
import subprocess

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PNG = os.path.join(ROOT, "tools", ".png_lockpick")
PAA = os.path.join(ROOT, "addons", "lockpick", "data")
SS = 4

random.seed(20260914)
os.makedirs(PNG, exist_ok=True)
os.makedirs(PAA, exist_ok=True)
written = []


def save(img, name):
    img.save(os.path.join(PNG, name + ".png"))
    written.append((name, img.size))


def noise(size, scale, sigma=50):
    w, h = size
    return Image.effect_noise((max(2, w // scale), max(2, h // scale)), sigma).resize(size, Image.BICUBIC)


def tint(gray, rgb):
    lut = lambda c: [max(0, min(255, int(c * v / 128))) for v in range(256)]
    return Image.merge("RGB", tuple(gray.point(lut(c)) for c in rgb))


def ramp(length, stops, horizontal=False):
    vals = []
    for i in range(length):
        t = i / max(1, length - 1)
        for (t0, l0), (t1, l1) in zip(stops, stops[1:]):
            if t0 <= t <= t1:
                vals.append(int(l0 + (l1 - l0) * (t - t0) / max(1e-6, t1 - t0)))
                break
    img = Image.new("L", (length, 1) if horizontal else (1, length))
    img.putdata(vals)
    return img


def scratches(size, count, rgba, width=1, length=(6, 40)):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(count):
        x, y = random.uniform(0, size[0]), random.uniform(0, size[1])
        a = random.uniform(0, math.pi)
        ln = random.uniform(*length) * SS
        d.line([(x, y), (x + math.cos(a) * ln, y + math.sin(a) * ln)], fill=rgba, width=width)
    return layer


def grime(size, count, rgb, radius, alpha):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(count):
        r = random.uniform(*radius)
        x, y = random.uniform(0, size[0]), random.uniform(0, size[1])
        d.ellipse([x - r, y - r, x + r, y + r], fill=rgb + (int(alpha * random.uniform(0.4, 1)),))
    return layer.filter(ImageFilter.GaussianBlur(radius[1] * 0.5))


def metal(size, base, vertical_stops, grain_scale=10, strength=0.25):
    """Brushed metal: a shading ramp, brushed horizontally, tinted."""
    w, h = size
    shade = ramp(h, vertical_stops).resize((w, h))
    brush = Image.effect_noise((max(2, w // 60), h), 40).resize((w, h), Image.BICUBIC)
    g = ImageChops.add(shade, brush.point(lambda v: int((v - 128) * strength)), scale=1, offset=0)
    return tint(g, base)


def down(img, size):
    return img.resize(size, Image.LANCZOS)


# --------------------------------------------------------------------------
# cutaway
# --------------------------------------------------------------------------
# Board fractions used by fn_drawCutaway: shear line at y 0.50, keyway top at
# y 0.86, housing top at y 0.06.
def make_housing():
    size = (1024, 256)
    W, H = size[0] * SS, size[1] * SS
    shear, keyway = int(H * 0.50), int(H * 0.86)

    img = Image.new("RGB", (W, H), (20, 20, 18))
    steel = metal((W, shear - int(H * 0.04)), (104, 106, 102), [(0, 150), (0.5, 120), (1, 90)])
    img.paste(steel, (0, int(H * 0.04)))
    brass = metal((W, keyway - shear), (150, 118, 58), [(0, 170), (0.4, 140), (1, 100)])
    img.paste(brass, (0, shear))
    key = metal((W, H - keyway), (40, 38, 34), [(0, 60), (1, 30)], strength=0.1)
    img.paste(key, (0, keyway))

    d = ImageDraw.Draw(img)
    d.line([(0, shear), (W, shear)], fill=(28, 26, 22), width=3 * SS)          # shear line gap
    d.line([(0, shear + 3 * SS), (W, shear + 3 * SS)], fill=(196, 160, 90), width=SS)
    d.line([(0, keyway), (W, keyway)], fill=(24, 22, 20), width=2 * SS)
    img = Image.alpha_composite(img.convert("RGBA"), scratches((W, H), 90, (230, 220, 190, 40), SS))
    img = Image.alpha_composite(img, grime((W, H), 30, (30, 26, 18), (20 * SS, 80 * SS), 90))
    save(down(img.convert("RGB"), size), "lp_housing_co")


def make_bore():
    size = (64, 256)
    W, H = size[0] * SS, size[1] * SS
    bore = ramp(W, [(0, 30), (0.25, 60), (0.6, 48), (1, 22)], horizontal=True).resize((W, H))
    img = tint(bore, (60, 58, 52)).convert("RGBA")
    edge = Image.new("L", (W, H), 0)
    ImageDraw.Draw(edge).rectangle([4 * SS, 0, W - 4 * SS, H], fill=255)
    img.putalpha(edge)
    save(down(img, size), "lp_bore_ca")


def make_pin(name, base, pointed):
    size = (64, 256)
    W, H = size[0] * SS, size[1] * SS
    body = ramp(W, [(0, 70), (0.3, 200), (0.55, 150), (1, 60)], horizontal=True).resize((W, H))
    img = tint(body, base).convert("RGBA")
    mask = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(mask)
    x0, x1 = 12 * SS, W - 12 * SS
    if pointed:
        d.rounded_rectangle([x0, 0, x1, H - 40 * SS], radius=6 * SS, fill=255)
        d.polygon([(x0, H - 44 * SS), (x1, H - 44 * SS), (W / 2, H - 2 * SS)], fill=255)
    else:
        d.rounded_rectangle([x0, 2 * SS, x1, H - 2 * SS], radius=10 * SS, fill=255)
    img = Image.alpha_composite(img, scratches((W, H), 10, (255, 240, 200, 50), SS, (4, 14)))
    img.putalpha(mask)
    save(down(img, size), name)


def make_spring():
    size = (64, 256)
    W, H = size[0] * SS, size[1] * SS
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    coils = 12
    pts = []
    for i in range(coils * 20 + 1):
        t = i / (coils * 20)
        pts.append((W / 2 + math.sin(t * coils * 2 * math.pi) * (W * 0.32), t * H))
    d.line(pts, fill=(40, 40, 38, 255), width=7 * SS)
    d.line(pts, fill=(170, 170, 160, 255), width=4 * SS)
    d.line([(x - SS, y) for x, y in pts], fill=(230, 230, 220, 160), width=SS)
    save(down(img, size), "lp_spring_ca")


def tool_sprite(name, draw_fn):
    size = (1024, 128)
    W, H = size[0] * SS, size[1] * SS
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_fn(img, ImageDraw.Draw(img), W, H)
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    shadow.putalpha(ImageChops.offset(img.split()[3], 3 * SS, 5 * SS).filter(ImageFilter.GaussianBlur(4 * SS))
                    .point(lambda v: v // 2))
    save(down(Image.alpha_composite(shadow, img), size), name)


def draw_kit_pick(img, d, W, H):
    # Hook pick: tip at the far LEFT, rising hook, long shaft, rubber handle right.
    cy = H * 0.62
    d.rectangle([W * 0.03, cy - 4 * SS, W * 0.66, cy + 4 * SS], fill=(186, 188, 184, 255))
    d.polygon([(W * 0.01, cy - 26 * SS), (W * 0.035, cy - 26 * SS), (W * 0.05, cy + 4 * SS),
               (W * 0.03, cy + 4 * SS)], fill=(196, 198, 194, 255))
    d.line([(W * 0.03, cy - 2 * SS), (W * 0.66, cy - 2 * SS)], fill=(240, 240, 236, 200), width=SS)
    d.rounded_rectangle([W * 0.64, cy - 22 * SS, W * 0.99, cy + 22 * SS], radius=18 * SS, fill=(34, 34, 36, 255))
    for i in range(10):
        x = W * (0.67 + i * 0.03)
        d.line([(x, cy - 18 * SS), (x, cy + 18 * SS)], fill=(58, 58, 60, 255), width=3 * SS)


def draw_clip_pick(img, d, W, H):
    # Straightened paperclip with a crude bent tip and a leftover loop.
    cy = H * 0.62
    pts = [(W * 0.01, cy - 22 * SS), (W * 0.04, cy), (W * 0.62, cy), (W * 0.64, cy - 4 * SS)]
    d.line(pts, fill=(60, 62, 64, 255), width=9 * SS, joint="curve")
    d.line(pts, fill=(176, 180, 184, 255), width=6 * SS, joint="curve")
    d.ellipse([W * 0.62, cy - 30 * SS, W * 0.78, cy + 22 * SS], outline=(60, 62, 64, 255), width=9 * SS)
    d.ellipse([W * 0.62, cy - 30 * SS, W * 0.78, cy + 22 * SS], outline=(176, 180, 184, 255), width=6 * SS)


def draw_rake(img, d, W, H):
    cy = H * 0.62
    teeth = [(W * 0.01, cy)]
    for i in range(9):
        x = W * (0.02 + i * 0.022)
        teeth += [(x, cy - (20 if i % 2 else 8) * SS)]
    teeth += [(W * 0.22, cy)]
    d.line(teeth, fill=(196, 198, 194, 255), width=6 * SS, joint="curve")
    d.rectangle([W * 0.21, cy - 4 * SS, W * 0.66, cy + 4 * SS], fill=(186, 188, 184, 255))
    d.rounded_rectangle([W * 0.64, cy - 22 * SS, W * 0.99, cy + 22 * SS], radius=18 * SS, fill=(34, 34, 36, 255))


def make_wrench(name, clip):
    size = (256, 128)
    W, H = size[0] * SS, size[1] * SS
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    col, dark = ((176, 180, 184, 255), (60, 62, 64, 255)) if clip else ((150, 152, 148, 255), (40, 40, 40, 255))
    wdt = 7 * SS if clip else 12 * SS
    pts = [(W * 0.95, H * 0.70), (W * 0.30, H * 0.70), (W * 0.30, H * 0.05)]
    d.line(pts, fill=dark, width=wdt + 3 * SS, joint="curve")
    d.line(pts, fill=col, width=wdt, joint="curve")
    save(down(img, size), name)


# --------------------------------------------------------------------------
# face view
# --------------------------------------------------------------------------
def make_door():
    size = (1024, 256)
    W, H = size[0] * 2, size[1] * 2
    base = Image.new("L", (W, H), 128)
    streaks = Image.effect_noise((W, 8), 60).resize((W, H), Image.BICUBIC)
    base = ImageChops.add(base, streaks.point(lambda v: (v - 128) // 2 + 128), scale=2.0)
    wood = tint(base, (96, 64, 38)).convert("RGBA")
    d = ImageDraw.Draw(wood)
    for _ in range(40):
        y = random.uniform(0, H)
        d.line([(0, y), (W, y + random.uniform(-6, 6))], fill=(58, 36, 20, 90), width=random.choice([1, 2]))
    wood = Image.alpha_composite(wood, grime((W, H), 20, (20, 12, 6), (40, 160), 90))
    save(down(wood.convert("RGB"), size), "lp_door_co")


def make_face():
    size = (512, 512)
    W, H = size[0] * SS, size[1] * SS
    c = W / 2
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([W * 0.06, H * 0.08, W * 0.98, H * 1.0], fill=(0, 0, 0, 170))
    img = Image.alpha_composite(img, sh.filter(ImageFilter.GaussianBlur(14 * SS)))
    ring = Image.new("L", (W, H), 0)
    ImageDraw.Draw(ring).ellipse([W * 0.04, H * 0.04, W * 0.96, H * 0.96], fill=255)
    light = Image.radial_gradient("L").resize((int(W * 1.6), int(H * 1.6))).crop((0, 0, W, H))
    face = tint(light.point(lambda v: 230 - v // 2), (120, 110, 90))
    face = Image.alpha_composite(face.convert("RGBA"), scratches((W, H), 120, (240, 230, 200, 45), SS))
    face = Image.alpha_composite(face, grime((W, H), 18, (40, 34, 24), (20 * SS, 70 * SS), 110))
    d = ImageDraw.Draw(face)
    d.ellipse([W * 0.20, H * 0.20, W * 0.80, H * 0.80], outline=(50, 46, 38), width=6 * SS)
    for a in range(0, 360, 90):
        x, y = c + math.cos(math.radians(a + 45)) * W * 0.38, c + math.sin(math.radians(a + 45)) * H * 0.38
        d.ellipse([x - 12 * SS, y - 12 * SS, x + 12 * SS, y + 12 * SS], fill=(70, 66, 56))
        d.line([(x - 8 * SS, y), (x + 8 * SS, y)], fill=(30, 28, 24), width=3 * SS)
    face.putalpha(ring)
    img = Image.alpha_composite(img, face)
    save(down(img, size), "lp_face_ca")


def make_plug_frames():
    size = (256, 256)
    W, H = size[0] * SS, size[1] * SS
    c = W / 2
    disc = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).ellipse([W * 0.04, H * 0.04, W * 0.96, H * 0.96], fill=255)
    light = Image.radial_gradient("L").resize((int(W * 1.5), int(H * 1.5))).crop((W // 8, H // 8, W // 8 + W, H // 8 + H))
    brass = tint(light.point(lambda v: 235 - v // 2), (160, 126, 62)).convert("RGBA")
    brass = Image.alpha_composite(brass, scratches((W, H), 60, (255, 240, 190, 50), SS, (4, 20)))
    brass.putalpha(mask)
    rim = ImageDraw.Draw(brass)
    rim.ellipse([W * 0.04, H * 0.04, W * 0.96, H * 0.96], outline=(70, 54, 26, 255), width=5 * SS)

    for i in range(19):
        angle = i * 5
        frame = brass.copy()
        slot = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        sd = ImageDraw.Draw(slot)
        sd.rounded_rectangle([c - 9 * SS, H * 0.18, c + 9 * SS, H * 0.62], radius=6 * SS, fill=(14, 12, 10, 255))
        sd.ellipse([c - 22 * SS, H * 0.55, c + 22 * SS, H * 0.72], fill=(14, 12, 10, 255))
        slot = slot.rotate(-angle, resample=Image.BICUBIC, center=(c, c))
        frame = Image.alpha_composite(frame, slot)
        save(down(frame, size), "lp_plug_%02d_ca" % i)


def make_dial_pick_frames():
    """Greyscale pick seen end-on: a shaft from the keyhole out to a handle."""
    size = (256, 256)
    W, H = size[0] * SS, size[1] * SS
    c = W / 2
    for i in range(31):
        angle = -90 + i * 6                      # 0 points straight up
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        a = math.radians(angle - 90)
        x1, y1 = c + math.cos(a) * W * 0.47, c + math.sin(a) * H * 0.47
        d.line([(c, c), (x1, y1)], fill=(40, 40, 40, 255), width=9 * SS)
        d.line([(c, c), (x1, y1)], fill=(215, 215, 215, 255), width=5 * SS)
        hx, hy = c + math.cos(a) * W * 0.40, c + math.sin(a) * H * 0.40
        d.ellipse([hx - 16 * SS, hy - 16 * SS, hx + 16 * SS, hy + 16 * SS], fill=(90, 90, 90, 255))
        shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        shadow.putalpha(ImageChops.offset(img.split()[3], 4 * SS, 6 * SS).filter(ImageFilter.GaussianBlur(4 * SS))
                        .point(lambda v: v // 2))
        save(down(Image.alpha_composite(shadow, img), size), "lp_dpick_%02d_ca" % i)


def convert():
    candidates = [
        r"E:\SteamLibrary\steamapps\common\Arma 3 Tools\ImageToPAA\ImageToPAA.exe",
        r"C:\Program Files (x86)\Steam\steamapps\common\Arma 3 Tools\ImageToPAA\ImageToPAA.exe",
    ]
    tool = next((c for c in candidates if os.path.exists(c)), shutil.which("ImageToPAA"))
    if not tool:
        print("ImageToPAA not found - PNGs left in", PNG)
        return
    failed = []
    for name, _ in written:
        dst = os.path.join(PAA, name + ".paa")
        if os.path.exists(dst):
            os.remove(dst)
        subprocess.run([tool, os.path.join(PNG, name + ".png"), dst], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if not os.path.exists(dst):
            failed.append(name)
    print("converted %d/%d%s" % (len(written) - len(failed), len(written), "" if not failed else " FAILED: " + ", ".join(failed)))


if __name__ == "__main__":
    make_housing()
    make_bore()
    make_pin("lp_keypin_ca", (176, 138, 66), True)
    make_pin("lp_driverpin_ca", (150, 152, 150), False)
    make_spring()
    tool_sprite("lp_pick_kit_ca", draw_kit_pick)
    tool_sprite("lp_pick_clip_ca", draw_clip_pick)
    tool_sprite("lp_rake_ca", draw_rake)
    make_wrench("lp_wrench_kit_ca", False)
    make_wrench("lp_wrench_clip_ca", True)
    make_door()
    make_face()
    make_plug_frames()
    make_dial_pick_frames()
    bad = [n for n, (w, h) in written if (w & (w - 1)) or (h & (h - 1))]
    print("%d textures, non power-of-two: %s" % (len(written), bad or "none"))
    convert()
