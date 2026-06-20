#!/usr/bin/env python3
"""Inline data/*.json -> build/data.js so the slice opens via file:// (no server).
Canonical data tetap di data/*.json (arsitektur data-eksternal, siap dipakai ulang Godot)."""
import json, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
OUT = ROOT / "build" / "data.js"

bundle = {}
for name in ["types", "moves", "crypture", "world"]:
    bundle[name] = json.loads((DATA / f"{name}.json").read_text(encoding="utf-8"))

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(
    "window.GAME_DATA = " + json.dumps(bundle, ensure_ascii=False, indent=2) + ";\n",
    encoding="utf-8",
)
print(f"Wrote {OUT} ({OUT.stat().st_size} bytes)")
