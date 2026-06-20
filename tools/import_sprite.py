#!/usr/bin/env python3
"""Impor sprite Crypture: buang latar kotak-kotak transparansi (yang ter-bake), trim, simpan.
Pakai:  python3 tools/import_sprite.py <file_gambar> <nama>
Contoh: python3 tools/import_sprite.py ~/Downloads/verduck.png verduck
Output: godot/assets/crypture/<nama>.png (transparan, ter-crop, persegi)."""
import sys, pathlib
import numpy as np
from PIL import Image
from collections import deque

if len(sys.argv) != 3:
    print(__doc__); sys.exit(1)
src, name = sys.argv[1], sys.argv[2].lower()
OUT = pathlib.Path(__file__).resolve().parent.parent / "godot" / "assets" / "crypture" / f"{name}.png"

im = Image.open(src).convert("RGB")
a = np.asarray(im).astype(np.int16)
h, w, _ = a.shape
mx, mn = a.max(2), a.min(2)
gray = ((mx - mn) <= 22) & (mn >= 150)  # piksel abu/putih terang = latar checkerboard

# BFS dari tepi: hapus hanya latar yg tersambung ke pinggir (mata/highlight di dalam aman)
visited = np.zeros((h, w), bool)
dq = deque()
for x in range(w):
    for y in (0, h - 1):
        if gray[y, x] and not visited[y, x]:
            visited[y, x] = True; dq.append((y, x))
for y in range(h):
    for x in (0, w - 1):
        if gray[y, x] and not visited[y, x]:
            visited[y, x] = True; dq.append((y, x))
while dq:
    y, x = dq.popleft()
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ny, nx = y + dy, x + dx
        if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and gray[ny, nx]:
            visited[ny, nx] = True; dq.append((ny, nx))

rgba = np.dstack([a.astype(np.uint8), np.where(visited, 0, 255).astype(np.uint8)])
out = Image.fromarray(rgba, "RGBA").crop(Image.fromarray(rgba, "RGBA").getbbox())
sz = max(out.size) + max(out.size) // 12
canvas = Image.new("RGBA", (sz, sz), (0, 0, 0, 0))
canvas.paste(out, ((sz - out.size[0]) // 2, (sz - out.size[1]) // 2), out)
OUT.parent.mkdir(parents=True, exist_ok=True)
canvas.save(OUT)
print(f"OK -> {OUT}  ({canvas.size[0]}x{canvas.size[1]}, latar transparan)")
print("Jalankan Godot sekali agar ter-import (atau buka project).")
