#!/usr/bin/env python3
"""Bikin sprite PLACEHOLDER sementara (badan + mata, warna per-tipe) untuk tiap Crypture.
Output: godot/assets/crypture/<nama lowercase>.png (256x256, transparan).
Ganti dengan art asli cukup menimpa file bernama sama. Bukan art final."""
import json, pathlib, math
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
types = json.loads((ROOT / "data" / "types.json").read_text(encoding="utf-8"))
crypt = json.loads((ROOT / "data" / "crypture.json").read_text(encoding="utf-8"))
colors = types["colors"]
OUT = ROOT / "godot" / "assets" / "crypture"
OUT.mkdir(parents=True, exist_ok=True)

def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def shade(rgb, f):
    return tuple(max(0, min(255, int(c * f))) for c in rgb)

S = 256
for sp in crypt["crypture"]:
    name = sp["name"]
    base = hex2rgb(colors.get(sp["types"][0], "#999999"))
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2 + 14
    rx, ry = 92, 86
    # bayangan lembut
    d.ellipse([cx - 70, S - 44, cx + 70, S - 20], fill=(0, 0, 0, 60))
    # badan
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=base + (255,), outline=shade(base, 0.6) + (255,), width=6)
    # perut lebih terang
    d.ellipse([cx - 56, cy - 6, cx + 56, cy + ry - 8], fill=shade(base, 1.25) + (235,))
    # telinga/jambul kecil (dua tonjolan)
    for sx in (-50, 50):
        d.ellipse([cx + sx - 26, cy - ry - 30, cx + sx + 26, cy - ry + 26], fill=base + (255,), outline=shade(base, 0.6) + (255,), width=5)
    # mata
    for ex in (-34, 34):
        d.ellipse([cx + ex - 20, cy - 44, cx + ex + 20, cy - 4], fill=(255, 255, 255, 255))
        d.ellipse([cx + ex - 9, cy - 34, cx + ex + 9, cy - 16], fill=(25, 25, 30, 255))
        d.ellipse([cx + ex - 4, cy - 33, cx + ex + 2, cy - 27], fill=(255, 255, 255, 255))
    # pipi
    for ex in (-58, 58):
        d.ellipse([cx + ex - 12, cy - 6, cx + ex + 12, cy + 12], fill=shade(base, 0.8) + (120,))
    img.save(OUT / f"{name.lower()}.png")
    print("sprite:", name.lower() + ".png")

print("Selesai. Taruh art asli dengan nama sama untuk menimpa.")
