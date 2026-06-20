# Crypture: Lost Avalon — Vertical Slice (Verdwall)

Implementasi **web (HTML/JS)** dari GDD + Data Spec, dibangun sebagai *playable blueprint*:
seluruh **otak & data** game sengaja dipisah dari engine, agar bisa dipindah ke Godot 4 belakangan tanpa kerja terbuang.

> Lingkup = vertical slice (satu loop utuh ±20–30 menit), bukan game penuh. Lihat GDD Bagian 6.

## Cara melihat (paling cepat)

Buka berkas tunggal — **tidak perlu server**:

```
dist/crypture-slice.html   ← klik dua kali / buka di browser
```

Atau jalankan versi modular (data eksternal) lewat server statis:

```bash
python3 tools/build_data.py            # data/*.json -> build/data.js
python3 -m http.server 8000            # lalu buka http://localhost:8000
```

## Loop yang bisa dimainkan

Intro (3 starter auto-Bond) → **Hub** (Papan Ekspedisi, NPC/buku sumber Codex, Kelola Tim, Codex) →
**Zona** Hutan Luar (gerak WASD/panah, Crypture terlihat di peta, titik lore) →
**Battle** turn-based (party 3, type matchup, HP musuh tersembunyi, aksi Seeker) →
**Codex → Bond** → lapor, dapat **GP**, naik **Rank** → klimaks **Eldergrove** (Apex, tak bisa di-Bond).

## Arsitektur (Data Spec, GDD Bagian 8 & 10)

Prinsip kunci: **konten = data eksternal, bukan hardcode**. Tambah Crypture cukup +1 entri di `data/crypture.json`.

```
data/
  types.json      Type chart (entri non-1.0; loader isi sisanya 1.0)
  moves.json      Skema Move (8.2)
  crypture.json   Skema Crypture (8.1) + info_sources (8.4)
  world.json      Rank/GP, Hub, Zona, Misi
src/
  loader.js       Data eksternal -> runtime; type chart; instance + growth_curve
  codex.js        Codex 0..100% per Crypture; Bond rate = Codex %
  battle.js       Seeker-commander, turn queue, type multiplier, HP hidden, Apex
  world.js        State, core loop, Rank/GP, progres misi
  ui.js           Presentasi (Hub / Zona canvas / Battle / Codex)
tools/
  build_data.py   Inline JSON -> build/data.js (agar jalan via file://)
  build_single.py Bundel semua -> dist/crypture-slice.html
  test.js         Uji logika (loader, battle balance, Codex/Bond, loop)
  smoke_ui.js     Smoke test UI boot (DOM tiruan)
```

## Verifikasi

```bash
node tools/test.js        # data/loader, battle (sim 200x), Codex->Bond, GP->Rank
node tools/smoke_ui.js    # UI boot tanpa error runtime
```

## Status vs dokumen

LOCKED yang sudah jalan: Bond-via-Codex; Seeker-commander + party 3; basic attack + skill role;
HP hidden + encounter lebih kuat (`wild_multiplier`); stat growth fixed; ability unlock by level;
tim hanya diatur di Hub; Eldergrove Apex (tak di-Bond, fase Murka, win = lemahkan ke ambang).

EKSPERIMEN/DITUNDA (sesuai dokumen, belum diaktifkan di slice): TM/slot custom; move tier (+/++).

**Catatan balance:** angka stat/power/multiplier bersifat *provisional* (balance pass), sesuai catatan Data Spec —
yang dikunci adalah **struktur** datanya.
