#!/usr/bin/env python3
"""Bundel index.html + build/data.js + src/*.js -> dist/crypture-slice.html (satu file, klik-buka)."""
import pathlib, re

ROOT = pathlib.Path(__file__).resolve().parent.parent
html = (ROOT / "index.html").read_text(encoding="utf-8")

scripts = ["build/data.js", "src/loader.js", "src/codex.js", "src/battle.js", "src/world.js", "src/ui.js"]
inline = "\n".join(
    f"<script>\n/* ===== {s} ===== */\n" + (ROOT / s).read_text(encoding="utf-8") + "\n</script>"
    for s in scripts
)

# Hapus tag <script src=...> dan komentar pemuatnya, sisakan UI.boot()
for s in scripts:
    html = re.sub(r'<script src="' + re.escape(s) + r'"></script>\s*', "", html)
html = html.replace("<!-- data eksternal (di-inline dari data/*.json oleh tools/build_data.py agar jalan via file://) -->\n  ", "")
html = html.replace("<script>UI.boot();</script>", inline + "\n<script>UI.boot();</script>")

out = ROOT / "dist" / "crypture-slice.html"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(html, encoding="utf-8")
print(f"Wrote {out} ({out.stat().st_size} bytes)")
