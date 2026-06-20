#!/usr/bin/env python3
"""Aset placeholder untuk prototipe eksplorasi 2.5D: figur Seeker & pohon. -> godot/assets/world/"""
import pathlib
from PIL import Image, ImageDraw

OUT = pathlib.Path(__file__).resolve().parent.parent / "godot" / "assets" / "world"
OUT.mkdir(parents=True, exist_ok=True)

# --- Seeker (figur pemain) 128x192 ---
img = Image.new("RGBA", (128, 192), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.ellipse([34, 170, 94, 188], fill=(0, 0, 0, 70))                 # bayangan
d.polygon([(64, 78), (30, 182), (98, 182)], fill=(58, 92, 120))    # jubah
d.polygon([(64, 78), (40, 182), (64, 182)], fill=(70, 108, 138))   # lipatan terang
d.ellipse([46, 36, 82, 74], fill=(232, 206, 178))                  # kepala
d.ellipse([40, 28, 88, 52], fill=(74, 60, 48))                     # topi (brim)
d.ellipse([50, 16, 78, 40], fill=(92, 74, 58))                     # topi (atas)
d.ellipse([56, 50, 62, 56], fill=(40, 36, 34))                     # mata
d.ellipse([68, 50, 74, 56], fill=(40, 36, 34))
img.save(OUT / "seeker.png")

# --- Pohon 160x208 ---
img = Image.new("RGBA", (160, 208), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.ellipse([40, 188, 120, 204], fill=(0, 0, 0, 70))                 # bayangan
d.rectangle([72, 120, 90, 196], fill=(94, 66, 44))                 # batang
for (cx, cy, r, col) in [(80, 84, 60, (74, 120, 70)), (50, 104, 44, (88, 138, 82)),
                         (112, 104, 44, (88, 138, 82)), (80, 60, 46, (104, 158, 96))]:
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)
img.save(OUT / "tree.png")
print("wrote seeker.png, tree.png ->", OUT)
