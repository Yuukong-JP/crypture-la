# Crypture: Lost Avalon — Godot 4 (Vertical Slice Verdwall)

Port produksi dari prototipe web ke **Godot 4** (engine yang dikunci dokumen). Sistem & data sama persis;
data tetap **JSON eksternal** (Data Spec: "JSON atau Godot Resource"), jadi konten dari versi web reusable.

## Menjalankan

Buka folder `godot/` di **Godot 4.3+**, tekan ▶ (main scene `res://scenes/Main.tscn`).

## Verifikasi (headless, tanpa editor)

```bash
# 1) Uji logika: data/loader, type chart, battle balance, Codex->Bond, GP->Rank
godot --headless --path godot --script res://tests/test_runner.gd

# 2) Smoke alur UI: intro->hub->team->codex->zona->encounter->battle->resolve
godot --headless --path godot --script res://tests/ui_smoke.gd

# 3) Boot scene utama (cek tak ada error _ready)
godot --headless --path godot --quit-after 20
```

Hasil acuan (Godot 4.3): semua test **LULUS** — tim menang 200/200 vs wild Common, rata-rata ~7–8 ronde,
Eldergrove (Apex) winrate **naif 0% vs pintar 100%** (strategi menentukan, sesuai GDD Bagian 4).

## Struktur

```
godot/
  project.godot          Autoload: Core (db/codex/state)
  data/*.json            Konten eksternal (sama dgn root /data) — tambah Crypture = +1 entri
  scripts/
    GameData.gd          Loader JSON, type chart, instance + growth_curve (port loader.js)
    Codex.gd             Codex %, Bond rate, info_sources (port codex.js)
    Battle.gd            Commander turn-based, HP hidden, aksi Seeker, Apex (port battle.js)
    GameState.gd         Rank/GP, misi, core loop (port world.js)
    Core.gd              Autoload singleton pemegang instance
  scenes/
    Main.tscn / Main.gd  Screen manager + UI (dibangun via kode)
    ZoneView.gd          Eksplorasi grid (gerak bebas, wild terlihat, lore)
  tests/
    test_runner.gd       Uji logika headless
    ui_smoke.gd          Uji alur UI headless
    Shooter.gd/.tscn     Render screenshot (dev tool; pakai Xvfb)
```

## Catatan

- **Sprite/art placeholder** (lingkaran berwarna per-tipe). Aesthetic Ghibli yang di-LOCK = lapisan visual
  terpisah; data & logika tak berubah saat sprite asli masuk.
- **Balance angka** (stat/power/multiplier) provisional — yang dikunci adalah **struktur** data (sesuai Data Spec).
- Jika ingin menukar JSON ke Godot Resource (.tres) nanti, hanya `GameData.gd` yang berubah; sisanya tetap.
