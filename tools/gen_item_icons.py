# -*- coding: utf-8 -*-
"""Inventory icons for the stand-in lockpicking tools (addons/lockpick_items).

    python tools/gen_item_icons.py

256x256 with alpha, drawn at 4x and downsampled, then converted to PAA.
"""
import math
import os
import shutil
import subprocess

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PNG = os.path.join(ROOT, "tools", ".png_items")
PAA = os.path.join(ROOT, "addons", "lockpick_items", "data")
SIZE = 256
SS = 4
os.makedirs(PNG, exist_ok=True)
os.makedirs(PAA, exist_ok=True)


def finish(img, name):
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow.putalpha(img.split()[3].filter(ImageFilter.GaussianBlur(5 * SS)).point(lambda v: v // 2))
    out = Image.alpha_composite(shadow, img).resize((SIZE, SIZE), Image.LANCZOS)
    path = os.path.join(PNG, name + ".png")
    out.save(path)
    return name


def wire(d, pts, width, dark=(52, 54, 58, 255), light=(196, 200, 206, 255), shine=(236, 238, 242, 255)):
    d.line(pts, fill=dark, width=width + 4 * SS, joint="curve")
    d.line(pts, fill=light, width=width, joint="curve")
    d.line([(x - width * 0.18, y - width * 0.18) for x, y in pts], fill=shine, width=max(SS, width // 4), joint="curve")


def arc(cx, cy, r, a0, a1, steps=24):
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / steps)),
             cy + r * math.sin(math.radians(a0 + (a1 - a0) * i / steps))) for i in range(steps + 1)]


def paperclip():
    W = SIZE * SS
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # A classic clip, drawn upright then tilted, with one leg bent out straight
    # into a crude pick.
    s = W / 256
    pts = []
    pts += [(150 * s, 70 * s)]
    pts += arc(126 * s, 70 * s, 24 * s, 0, -180)[1:]
    pts += [(102 * s, 190 * s)]
    pts += arc(130 * s, 190 * s, 28 * s, 180, 0)[1:]
    pts += [(158 * s, 95 * s)]
    pts += arc(140 * s, 95 * s, 18 * s, 0, -180)[1:]
    pts += [(122 * s, 170 * s)]
    # the straightened leg with its bent tip
    pts += [(122 * s, 214 * s), (60 * s, 238 * s), (48 * s, 228 * s)]
    layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    wire(ImageDraw.Draw(layer), pts, 9 * SS)
    img = Image.alpha_composite(img, layer.rotate(-28, resample=Image.BICUBIC, center=(W / 2, W / 2)))
    return finish(img, "paperclip_ca")


def lockpick_kit():
    W = SIZE * SS
    s = W / 256
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Picks fanned out of the pouch: hook, rake, half-diamond, and a wrench.
    tools = [
        (-34, "hook"), (-14, "rake"), (6, "diamond"), (26, "hook"),
    ]
    for angle, kind in tools:
        layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        x = 128 * s
        ld.rectangle([x - 5 * s, 40 * s, x + 5 * s, 190 * s], fill=(52, 54, 58, 255))
        ld.rectangle([x - 3 * s, 42 * s, x + 3 * s, 190 * s], fill=(190, 194, 200, 255))
        if kind == "hook":
            ld.line([(x, 44 * s), (x - 12 * s, 30 * s), (x - 14 * s, 20 * s)], fill=(190, 194, 200, 255), width=int(6 * s), joint="curve")
        elif kind == "rake":
            ld.line([(x, 44 * s), (x - 8 * s, 36 * s), (x, 28 * s), (x - 8 * s, 20 * s), (x, 12 * s)], fill=(190, 194, 200, 255), width=int(5 * s), joint="curve")
        else:
            ld.polygon([(x - 3 * s, 44 * s), (x - 12 * s, 26 * s), (x + 3 * s, 18 * s), (x + 3 * s, 44 * s)], fill=(190, 194, 200, 255))
        img = Image.alpha_composite(img, layer.rotate(-angle, resample=Image.BICUBIC, center=(128 * s, 200 * s)))
    d = ImageDraw.Draw(img)
    # tension wrench across the front
    d.line([(58 * s, 150 * s), (58 * s, 128 * s), (150 * s, 128 * s)], fill=(40, 40, 42, 255), width=int(10 * s), joint="curve")
    d.line([(58 * s, 150 * s), (58 * s, 128 * s), (150 * s, 128 * s)], fill=(150, 152, 150, 255), width=int(6 * s), joint="curve")
    # leather pouch
    d.rounded_rectangle([40 * s, 150 * s, 216 * s, 236 * s], radius=int(14 * s), fill=(58, 38, 24, 255))
    d.rounded_rectangle([46 * s, 156 * s, 210 * s, 230 * s], radius=int(10 * s), outline=(120, 86, 52, 255), width=int(3 * s))
    d.rounded_rectangle([40 * s, 150 * s, 216 * s, 172 * s], radius=int(8 * s), fill=(76, 52, 32, 255))
    for i in range(14):
        xx = (54 + i * 11.5) * s
        d.line([(xx, 162 * s), (xx + 5 * s, 162 * s)], fill=(150, 116, 72, 255), width=int(2 * s))
    return finish(img, "lockpick_kit_ca")


def convert(names):
    candidates = [
        r"E:\SteamLibrary\steamapps\common\Arma 3 Tools\ImageToPAA\ImageToPAA.exe",
        r"C:\Program Files (x86)\Steam\steamapps\common\Arma 3 Tools\ImageToPAA\ImageToPAA.exe",
    ]
    tool = next((c for c in candidates if os.path.exists(c)), shutil.which("ImageToPAA"))
    if not tool:
        print("ImageToPAA not found - PNGs left in", PNG)
        return
    for name in names:
        dst = os.path.join(PAA, name + ".paa")
        if os.path.exists(dst):
            os.remove(dst)
        subprocess.run([tool, os.path.join(PNG, name + ".png"), dst], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(name, "ok" if os.path.exists(dst) else "FAILED")


if __name__ == "__main__":
    convert([paperclip(), lockpick_kit()])
