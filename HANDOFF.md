# HANDOFF — Crypture: Lost Avalon (lanjutan sesi baru)

Dokumen ini agar sesi/Claude baru bisa langsung melanjutkan tanpa konteks sebelumnya.
**Baca ini lebih dulu, lalu lanjutkan dari bagian "Langkah berikutnya".**

Owner non-teknis — tunjukkan progres lewat **screenshot**, jelaskan dalam Bahasa Indonesia, dan
**commit + push tiap milestone**. **Satu branch saja:** `claude/focused-ramanujan-1e5i2y`
(branch lama `claude/admiring-cannon-w4sg5x` sudah ditinggalkan — jangan dipakai lagi).

---

## 1. Apa ini
Creature-collector RPG turn-based (vertical slice "Verdwall"), arah visual **HD-2D / 2.5D** (ala Octopath):
sprite 2D billboard di dunia 3D miring. Ada GDD lengkap (docx) milik owner; intinya sudah tercermin di kode.

**Pilar desain (LOCKED di GDD):**
- **Bond via Codex** (hook utama): isi Codex 0→100% dari encounter/observasi skill/habitat/lore → success Bond = Codex %.
- **Seeker = commander**: pemain perintah 3 Crypture (party), Seeker mendukung lewat aksi (Potion/Scan/Bond), tak punya HP.
- **HP musuh tersembunyi** → ditampilkan kualitatif ("Segar/Terluka parah/…") + feedback ("Serangan telak!").
- **Encounter > versi Bond** (`wild_multiplier`). **Tim cuma diatur di Hub**, maks 3.
- **Eldergrove = Apex**: tak bisa di-Bond, fase Murka, menang = lemahkan ke ambang (uji kualitas strategi).
- **Data eksternal** (JSON): tambah Crypture = +1 entri, tanpa sentuh kode.
- Estetika di-LOCK Ghibli; owner condong pixel/HD-2D. Perspektif **2.5D** dipilih owner (jelajah + battle).

## 2. Dua implementasi
- **Web prototype** (root repo): `index.html`, `src/*.js`, `data/*.json` — "playable blueprint", masih dipakai untuk uji logika cepat (`node tools/test.js`). Buka `dist/crypture-slice.html` langsung.
- **Godot 4** (folder `godot/`) — **ini proyek utama yang dikembangkan sekarang.**

## 3. Arsitektur Godot (`godot/`)
- `project.godot` — autoload **Core** (`scripts/Core.gd`): `Core.db` (GameData), `Core.codex`, `Core.state`, `Core.new_battle(party, enemy)`.
- `data/*.json` — types, moves, crypture, world. **Sumber kebenaran = `data/` di ROOT repo**; setelah edit root, `cp data/*.json godot/data/` lalu `python3 tools/build_data.py` (rebuild web). 10 tipe inti, 10 Crypture.
- `scripts/`
  - `GameData.gd` — loader JSON, type chart, `make_instance(cid,lv,is_wild)`, `sprite_for(cid)`/`sprite_back_for(cid)`, `display_scale`.
  - `Codex.gd` — Codex %, bond_rate, info_sources.
  - `Battle.gd` — engine turn-based: queue by Speed, type mult, status (burn/sleep/taunt), aksi Seeker, Bond, Apex, `turn_forecast(n)`.
  - `GameState.gd` — Rank/GP, misi, `on_battle_result`.
- `scenes/`
  - `Main.gd` (main scene) — screen manager. UI 2D (intro/board/team/codex/balai/report) via `_set_body`; meluncurkan **HubTown3D** (kota), **ExploreZone3D** & **BattlePlay3D** sebagai child Node3D dan menyembunyikan UI 2D (`_show_ui(false)`). State persisten: `_explore_state`, `_hub_state`.
  - `HubTown3D.gd` — **Hub = KOTA 3D** (vibe gathering hub Monster Hunter): Seeker jalan (WASD), dekati stasiun (📋 board/⛺ team/📖 codex/💬 talk/🚪 depart) lalu tekan **E/Enter** → sinyal `station(kind)` ke Main. Main buka panel 2D terkait (atau `show_zone` utk depart). Posisi pemain disimpan (`get_state/apply_state`). Visual: plaza, rumah (Box+PrismMesh atap), lentera (OmniLight kedip), gerbang, warga (sprite seeker dimodulasi).
  - `ExploreZone3D.gd` — jelajah 2.5D: WASD, billboard creature/tree, lore ✨, EXIT, kamera 3/4 follow, idle-bob + wander/flee, `get_state/apply_state`. Sinyal: `encounter/reached_exit/go_hub/lore_collected`.
  - `BattlePlay3D.gd` — battle 2.5D: panggung 3D, kamera 3/4 (lihat `_setup_cam`), party **back-sprite** menghadap kanan + musuh, **bar Urutan Giliran** (ikon) di atas, **nameplate musuh** melayang (Label3D), juice (lunge/flash/angka damage), UI overlay (HP party, menu skill, aksi Seeker, log). Flag `animate` (Main=true, test=false). `display_scale` + kamera adaptif (musuh besar → mundur).
  - `ZoneView.gd` — versi 2D top-down LAMA, **tak dipakai** (boleh dihapus).
- `tests/` — `test_runner.gd` (logika headless) + banyak `Shooter*.tscn` (driver headless untuk screenshot): `ShooterPlay/ShooterGiant/ShooterIntegration/ShooterExplore/ShooterJuice`.
- `tools/` (di root, Python) — `import_sprite.py` (bersihkan latar checkerboard sprite owner → `assets/crypture/<nama>.png`), `gen_placeholder_sprites.py`, `gen_explore_assets.py`, `build_data.py`.

## 4. Konvensi penting (JANGAN langgar tanpa alasan)
- **Sprite path:** `godot/assets/crypture/<nama lowercase>.png` = front; `<nama>_back.png` = back. Dunia: `assets/world/seeker.png`, `tree.png`.
- **Back-sprite owner menghadap KANAN** → karena itu **musuh ditaruh di sisi kanan**, kamera dari kanan (yaw +25°). Party `PARTY_X=[-3.1,-1.1,0.9]` (kompensasi perspektif + lepas dari panel UI kanan).
- **`display_scale`** per-Crypture di data (Mosswhim 1.2, Eldergrove 1.8, Cappin 0.9, default 1.0). Tinggi musuh = `2.6*scale`, party diклamp 0.7–1.2.
- **Balance angka provisional**; yang dikunci STRUKTUR. Logika identik di web & Godot (port).
- Aturan emas GDD: jangan tambah konten/skala sebelum slice terbukti fun.

## 5. Status art (sprite asli owner)
Sudah ada: **Verduck** (front+back), **Pyruff** (front=rubah api + back), **Ripplet** (front=makhluk air + back), **Mosswhim** (front).
Masih placeholder: **Cappin, Glimmoth, Pebblion, Gustling, Brookling**, Eldergrove (semua front), + back utk yg belum.

**Cara pasang sprite dari owner:** owner kirim gambar di chat (sering webp/jpeg dengan latar kotak-kotak yang ter-*bake*).
File upload TIDAK ada di disk — gambar ter-embed base64 di transkrip `~/.claude/projects/<...>/<session>.jsonl`
(field `{"type":"base64","media_type":"image/...","data":...}`). Ekstrak → buang latar (flood-fill abu dari tepi +
ambil komponen tersambung terbesar; butuh `pip install Pillow numpy scipy`) → simpan ke `assets/crypture/`. Lihat `tools/import_sprite.py` (untuk file path) sebagai acuan algoritmanya. Lalu **`--import`** ulang.

## 6. Environment & verifikasi (PENTING untuk sesi baru)
Godot TIDAK terpasang, tapi bisa diunduh (egress mengizinkan github.com). Xvfb tersedia untuk screenshot.
```bash
# Ambil Godot 4.7 (project jalan di 4.3 & 4.7)
cd /tmp && curl -sL -o godot.zip \
  https://github.com/godotengine/godot-builds/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip
unzip -o -q godot.zip && chmod +x Godot_v4.7-stable_linux.x86_64
BIN=/tmp/Godot_v4.7-stable_linux.x86_64
pip install --quiet Pillow numpy scipy   # untuk olah sprite

# Uji logika (HARUS lulus sebelum & sesudah perubahan)
$BIN --headless --path godot --script res://tests/test_runner.gd     # Godot
node tools/test.js                                                    # Web

# Import aset (WAJIB setelah menamb/ubah PNG atau scene baru)
xvfb-run -a $BIN --headless --path godot --import

# Screenshot sebuah scene (output PNG ke /tmp/...)
xvfb-run -a -s "-screen 0 1000x680x24" $BIN --path godot res://tests/ShooterPlay.tscn
# Driver headless men-setел animate=false agar bisa di-step; Main menyalakan animate untuk pemain.
```
Owner menjalankan game di mesinnya: buka `godot/project.godot` di Godot 4.7 → **F5**. Battle saja: `BattlePlay3D.tscn` → F6.

## 7. Yang sudah selesai
Loop penuh terintegrasi & terverifikasi (Godot 4.7, semua test LULUS):
Intro → Hub (2D) → jelajah **2.5D** (WASD, creature hidup) → dekati Crypture → **battle 3/4** (turn queue, back-sprite,
juice) → menang/Bond → hasil (GP/misi) → lanjut/pulang → Rank. Sprite pipeline (front+back), display_scale,
kamera adaptif, Mosswhim (musuh baru #015).

> Catatan owner: UI battle masih "mentah" (kotak polos, font default Godot) — fase art-polish
> (font kustom, panel bergaya, ikon) dilakukan NANTI setelah fitur lengkap. Sekarang fokus fungsi.

## 8. Langkah berikutnya (menu — owner pilih)
1. **Pasang sprite sisanya** (owner kirim) — Cappin, Glimmoth, Pebblion, Gustling, Brookling, Eldergrove.
2. **Animasi aksi berurutan** di battle (sekarang resolusi engine sinkron → flash/number muncul bersamaan; bisa dibuat step-by-step dgn delay per aksi).
3. **Art polish UI lanjutan** — font kustom (.ttf), ikon, bingkai bertekstur. Theme dasar sudah ada (lihat di bawah).

**Sudah SELESAI:**
- Turn queue: bar vertikal **nempel kiri layar**, tiap baris kotak gradasi (pekat kiri → transparan
  kanan), **portrait close-up muka** (AtlasTexture auto-crop kepala via `_face_tex`, di-cache), nama +
  subjudul, **animasi meluncur** saat giliran berganti. Lihat `BattlePlay3D._build_queue/_turn_tile`.
- **Transisi masuk battle**: flash putih kedip ("Encounter!") → tutup → swap → reveal, +intro kamera
  meluncur masuk. Lihat `Main._battle_transition` & `BattlePlay3D._setup_cam` (blok `if animate`).
  CATATAN: `_on_encounter` kini **async** (await transisi) — driver/test harus tunggu `_battle3d != null`.
- **Hub/menu 2D dipercantik**: `Main._make_theme()` (Theme dasar: panel & tombol membulat berbingkai +
  state hover/pressed, ProgressBar membulat — warna via `modulate`), `_make_background()` (gradasi
  vertikal + vignette radial), top bar jadi banner beraksen emas + `_chip()` status. Belum pakai font
  kustom (font masih default Godot) — itu fase berikutnya.
- **Hub jadi KOTA 3D** (`HubTown3D`): Outpost Verdwall kini dijelajahi (WASD), stasiun interaksi ala
  Monster Hunter buka panel 2D (board/tim/codex/balai) atau berangkat ekspedisi. `show_hub()` di Main
  kini meluncurkan kota (bukan lagi menu 2D tunggal); konten lama dipecah jadi `show_board()` & `show_talk()`.

> Saran: #1 atau #2 (paling kerasa). Selalu: ubah → `--import` → screenshot → test → commit/push.
