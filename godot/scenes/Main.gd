# Main.gd — screen manager + UI (dibangun via kode agar .tscn minimal & tahan error).
# Loop: intro -> hub -> zona -> battle -> report. Memakai autoload Core (db/codex/state).
extends Control

const ExploreZone3DScene := preload("res://scenes/ExploreZone3D.tscn")
const BattlePlay3DScene := preload("res://scenes/BattlePlay3D.tscn")
const HubTown3DScene := preload("res://scenes/HubTown3D.tscn")

var top_rank: Label
var top_gp: Label
var top_loc: Label
var body: MarginContainer

var battle            # Battle aktif
var current_spawn     # spawn yang sedang ditempur
var _bg: Control      # latar UI bergradasi (disembunyikan saat scene 3D)
var _rootui: VBoxContainer
var _battle3d         # scene BattlePlay3D aktif
var _explore          # scene ExploreZone3D aktif
var _hub              # scene HubTown3D aktif (kota)
var _hub_state := {}  # posisi pemain di kota (terjaga lintas buka menu)
var _explore_state := {}  # posisi pemain + musuh terkalahkan + lore terpakai (lintas battle)
var _fighting_sid := -1   # sid creature yg sedang ditempur
var _fx_rect: ColorRect   # overlay layar-penuh utk transisi (flash putih masuk battle)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = _make_theme()
	_bg = _make_background()
	add_child(_bg)

	var root := VBoxContainer.new()
	_rootui = root
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	# Top bar — banner (bukan kartu membulat): bingkai bawah beraksen
	var bar := PanelContainer.new()
	var banner := _sbflat(Color(0.05, 0.10, 0.08, 0.96), 0, Color(0, 0, 0, 0), 0, 10)
	banner.border_color = Color("#e7c659"); banner.border_width_bottom = 2
	bar.add_theme_stylebox_override("panel", banner)
	var barbox := HBoxContainer.new()
	barbox.add_theme_constant_override("separation", 16)
	var brand := _label("✦ CRYPTURE · Lost Avalon", 16, Color("#e7c659"), false)
	top_rank = _chip("Rank —", Color("#9ed27f"))
	top_gp = _chip("GP 0", Color("#e7c659"))
	top_loc = _chip("—", Color("#8fb6d8"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barbox.add_child(brand)
	barbox.add_child(spacer)
	barbox.add_child(top_rank)
	barbox.add_child(top_gp)
	barbox.add_child(top_loc)
	bar.add_child(barbox)
	root.add_child(bar)

	# Body (scrollable)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	body = MarginContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for m in ["left", "right", "top", "bottom"]:
		body.add_theme_constant_override("margin_" + m, 18)
	scroll.add_child(body)

	show_intro()

# ---------- tema & latar (styling konsisten utk semua layar 2D) ----------
func _sbflat(bg: Color, corner: int, border_c: Color, border_w: int, pad: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(corner)
	s.border_color = border_c
	s.set_border_width_all(border_w)
	s.set_content_margin_all(pad)
	return s

func _make_theme() -> Theme:
	var t := Theme.new()
	# Panel (PanelContainer) — kartu konten
	t.set_stylebox("panel", "PanelContainer", _sbflat(Color(0.06, 0.12, 0.09, 0.88), 12, Color(0.22, 0.38, 0.29, 0.9), 1, 12))
	# Tombol — membulat, bingkai, ada state hover/pressed
	t.set_stylebox("normal", "Button", _sbflat(Color(0.10, 0.19, 0.14, 0.96), 9, Color(0.30, 0.48, 0.36), 1, 9))
	t.set_stylebox("hover", "Button", _sbflat(Color(0.17, 0.30, 0.22, 0.98), 9, Color(0.55, 0.80, 0.55), 1, 9))
	t.set_stylebox("pressed", "Button", _sbflat(Color(0.07, 0.14, 0.10, 0.98), 9, Color(0.45, 0.66, 0.46), 1, 9))
	t.set_stylebox("disabled", "Button", _sbflat(Color(0.08, 0.12, 0.10, 0.7), 9, Color(0.20, 0.28, 0.23), 1, 9))
	t.set_stylebox("focus", "Button", _sbflat(Color(0, 0, 0, 0), 9, Color(0.7, 0.9, 0.7, 0.6), 1, 9))
	t.set_color("font_color", "Button", Color("#eaf3ea"))
	t.set_color("font_hover_color", "Button", Color("#ffffff"))
	t.set_color("font_pressed_color", "Button", Color("#cfe0d0"))
	t.set_color("font_disabled_color", "Button", Color("#6b7d70"))
	# ProgressBar — membulat; warna asli diatur lewat modulate (putih * modulate = warna)
	t.set_stylebox("background", "ProgressBar", _sbflat(Color(0.04, 0.07, 0.06, 0.9), 6, Color(0.18, 0.28, 0.22), 1, 0))
	t.set_stylebox("fill", "ProgressBar", _sbflat(Color(1, 1, 1, 1), 6, Color(1, 1, 1, 0), 0, 0))
	return t

func _make_background() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# gradasi vertikal (hutan dalam): atas lebih terang -> bawah gelap
	var g := Gradient.new()
	g.set_color(0, Color("#1d3a2c"))
	g.set_color(1, Color("#0b1610"))
	g.offsets = [0.0, 1.0]
	var gt := GradientTexture2D.new()
	gt.gradient = g; gt.width = 8; gt.height = 256
	gt.fill_from = Vector2(0, 0); gt.fill_to = Vector2(0, 1)
	var tr := TextureRect.new()
	tr.texture = gt
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tr)
	# vignette: radial transparan di tengah -> gelap di tepi
	var vg := Gradient.new()
	vg.set_color(0, Color(0, 0, 0, 0))
	vg.set_color(1, Color(0, 0, 0, 0.45))
	vg.offsets = [0.35, 1.0]
	var vt := GradientTexture2D.new()
	vt.gradient = vg; vt.width = 256; vt.height = 256
	vt.fill = GradientTexture2D.FILL_RADIAL
	vt.fill_from = Vector2(0.5, 0.5); vt.fill_to = Vector2(1.0, 0.5)
	var vr := TextureRect.new()
	vr.texture = vt
	vr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vr.stretch_mode = TextureRect.STRETCH_SCALE
	vr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vr)
	return root

# Chip: Label berlatar membulat (status di top bar). `.text` tetap bisa di-set.
func _chip(text: String, accent: Color) -> Label:
	var l := _label(text, 13, accent, false)
	var sb := _sbflat(Color(0.10, 0.17, 0.13, 0.95), 8, accent, 1, 0)
	sb.content_margin_left = 10; sb.content_margin_right = 10
	sb.content_margin_top = 4; sb.content_margin_bottom = 4
	l.add_theme_stylebox_override("normal", sb)
	return l

# ---------- helper UI ----------
func _label(text: String, size := 14, color = null, wrap := true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	if color != null:
		l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	return b

func _panel(child: Control) -> PanelContainer:
	var p := PanelContainer.new()
	var mc := MarginContainer.new()
	for m in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + m, 10)
	mc.add_child(child)
	p.add_child(mc)
	return p

func _set_body(node: Control) -> void:
	while body.get_child_count() > 0:
		var c := body.get_child(0)
		body.remove_child(c)
		c.queue_free()
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(node)
	_refresh_topbar()

func _refresh_topbar() -> void:
	var st = Core.state
	top_rank.text = "Rank %d · %s" % [st.rank, st.rank_info(st.rank)["name"]]
	top_gp.text = "GP %d" % st.gp
	var nr = st.next_rank()
	if nr != null and not bool(nr.get("placeholder", false)):
		top_gp.text += " (→%s %d)" % [nr["name"], int(nr["gp_required"])]

func _set_loc(s: String) -> void:
	top_loc.text = s

func _screen() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	return v

# ---------- INTRO ----------
func show_intro() -> void:
	_set_loc("Prolog")
	var v := _screen()
	v.add_child(_label("Seorang Seeker, di tepi Verdwall", 22, Color("#eef3e9")))
	v.add_child(_label("Kamu bukan pemburu. Kamu tak menangkap makhluk dengan melempar bola — kamu MEMAHAMI mereka hingga mereka mau ber-Bond. Guild menyerahkan tiga sekutu pertamamu. Dunia terbuka karena reputasimu naik.", 14, Color("#a7c0ad")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for cid in ["001", "003", "005"]:
		var sp = Core.db.species[cid]
		var card := _screen()
		card.add_child(_label("%s" % sp["name"], 15, Color("#eef3e9")))
		card.add_child(_label("%s · peran %s" % [", ".join(sp["types"]), sp["role"]], 12, Color("#a7c0ad")))
		card.add_child(_label(sp["dex_entry"], 12, Color("#a7c0ad")))
		card.custom_minimum_size = Vector2(260, 0)
		row.add_child(_panel(card))
	v.add_child(row)
	v.add_child(_label("Tiga starter di-Bond otomatis lewat story (Bagian 5). Codex 100%.", 12, Color("#6fae57")))
	v.add_child(_button("Masuk ke Outpost Verdwall →", show_hub))
	_set_body(v)

# ---------- HUB = KOTA 3D (vibe gathering hub Monster Hunter) ----------
# Outpost Verdwall jadi kota yang bisa dijelajahi; stasiun membuka panel 2D (board/tim/codex/balai).
func show_hub() -> void:
	_set_loc("Outpost Verdwall (Kota)")
	_dispose_explore()
	_dispose_hub()
	_show_ui(false)
	_spawn_hub()

func _spawn_hub() -> void:
	_hub = HubTown3DScene.instantiate()
	_hub.station.connect(_on_hub_station)
	add_child(_hub)
	if not _hub_state.is_empty():
		_hub.apply_state(_hub_state)

func _dispose_hub() -> void:
	if _hub != null and is_instance_valid(_hub):
		_hub_state = _hub.get_state()
		_hub.queue_free()
	_hub = null

func _on_hub_station(kind: String) -> void:
	_dispose_hub()
	if kind == "depart":
		show_zone(); return
	_show_ui(true)
	match kind:
		"board": show_board()
		"team": show_team()
		"codex": show_codex()
		"talk": show_talk()

# Papan Ekspedisi (2D)
func show_board() -> void:
	_set_loc("Kota · Papan Ekspedisi")
	var st = Core.state
	var v := _screen()
	v.add_child(_label("📋 Papan Ekspedisi", 22, Color("#eef3e9")))
	v.add_child(_label("Terima kontrak Guild, lalu selesaikan di ekspedisi untuk Guild Points & naik Rank.", 14, Color("#a7c0ad")))
	var mis := _screen()
	for m in st.active_missions():
		mis.add_child(_mission_row(m, true))
	for m in st.available_missions():
		mis.add_child(_mission_row(m, false))
	if st.active_missions().is_empty() and st.available_missions().is_empty():
		mis.add_child(_label("Tidak ada kontrak tersedia.", 12, Color("#a7c0ad")))
	v.add_child(_panel(mis))
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 8)
	row.add_child(_button("← Kembali ke Kota", show_hub))
	row.add_child(_button("⛺ Berangkat ke Hutan →", show_zone))
	v.add_child(row)
	_set_body(v)

# Balai Warga & Arsip (2D) — NPC & buku = sumber lore Codex
func show_talk() -> void:
	_set_loc("Kota · Balai Warga")
	var v := _screen()
	v.add_child(_label("💬 Balai Warga & Arsip", 22, Color("#eef3e9")))
	v.add_child(_label("Ngobrol dengan penduduk & periksa buku — mengisi Codex Crypture langka (eksplorasi sosial = progres).", 14, Color("#a7c0ad")))
	var hubi := _screen()
	for it in Core.db.world["hub"]["interactions"]:
		var icon := "📖 " if it["kind"] == "book" else "💬 "
		hubi.add_child(_button(icon + it["name"], _on_interact.bind(it)))
	v.add_child(_panel(hubi))
	v.add_child(_button("← Kembali ke Kota", show_hub))
	_set_body(v)

func _mission_row(m: Dictionary, active: bool) -> Control:
	var c := _screen()
	var tag := "STORY" if m["type"] == "story" else "KONTRAK"
	c.add_child(_label("[%s] %s  (+%d GP)" % [tag, m["name"], int(m["gp"])], 14, Color("#eef3e9")))
	c.add_child(_label(m["desc"], 12, Color("#a7c0ad")))
	if active:
		c.add_child(_label("● Aktif — selesaikan di ekspedisi", 12, Color("#6fae57")))
	else:
		c.add_child(_button("Terima kontrak", _on_accept.bind(m["id"])))
	return _panel(c)

func _on_accept(id: String) -> void:
	Core.state.accept_mission(id)
	show_board()

func _on_interact(it: Dictionary) -> void:
	var events = Core.codex.add_lore_from_interaction(it)
	var v := _screen()
	v.add_child(_label(("📖 " if it["kind"] == "book" else "💬 ") + it["name"], 20, Color("#eef3e9")))
	v.add_child(_panel(_label("\"%s\"" % it["text"], 14, Color("#a7c0ad"))))
	if events.is_empty():
		v.add_child(_label("(Tidak ada entri Codex baru — mungkin sudah kamu catat.)", 12, Color("#a7c0ad")))
	else:
		for e in events:
			v.add_child(_label("📖 Codex %s +%d%% — %s" % [e["name"], e["amt"], e["detail"]], 13, Color("#6fae57")))
	v.add_child(_button("← Kembali ke Balai", show_talk))
	_set_body(v)

# Node sprite untuk sebuah Crypture; fallback kotak warna-tipe bila belum ada art.
func _sprite_node(cid: String, px: int) -> Control:
	var tex: Texture2D = Core.db.sprite_for(cid)
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = Vector2(px, px)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return tr
	var sp: Dictionary = Core.db.species[cid]
	var cr := ColorRect.new()
	cr.color = Color(Core.db.colors.get(sp["types"][0], "#999999"))
	cr.custom_minimum_size = Vector2(px, px)
	return cr

func _unit_row(inst: Dictionary, show_hp := true, extra_button: Control = null) -> Control:
	var c := _screen()
	var frac: float = float(inst["hp"]) / float(inst["max_hp"])
	c.add_child(_label("%s  Lv%d  [%s]  · %s" % [inst["name"], inst["level"], ", ".join(inst["types"]), inst["role"]], 14, Color("#eef3e9")))
	var bar := ProgressBar.new()
	bar.max_value = inst["max_hp"]
	bar.value = max(0, inst["hp"])
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(220, 12)
	bar.modulate = Color("#e0683b") if frac < 0.4 else Color("#6fae57")
	c.add_child(bar)
	if show_hp:
		var st := "  · 🔥" if inst["status"] == "burn" else ""
		c.add_child(_label("HP %d/%d%s" % [max(0, int(inst["hp"])), inst["max_hp"], st], 12, Color("#a7c0ad")))
	if extra_button != null:
		c.add_child(extra_button)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	var spr := _sprite_node(inst["cid"], 56)
	spr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(spr)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(c)
	return _panel(hb)

# ---------- TEAM ----------
func show_team() -> void:
	_set_loc("Hub · Kelola Tim")
	_build_team()

func _build_team() -> void:
	var st = Core.state
	var v := _screen()
	v.add_child(_label("Kelola Tim", 22, Color("#eef3e9")))
	v.add_child(_label("Tim hanya bisa diatur di Hub, maks 3 (LOCKED). Party = komitmen.", 14, Color("#a7c0ad")))
	v.add_child(_label("Tim Aktif", 13, Color("#a7c0ad")))
	for i in range(st.party.size()):
		var p = st.party[i]
		var btn := _button("Cadangkan", _on_bench.bind(i))
		btn.disabled = st.party.size() <= 1
		v.add_child(_unit_row(p, true, btn))
	v.add_child(_label("Koleksi (ter-Bond)", 13, Color("#a7c0ad")))
	for inst in Core.codex.bonded:
		var in_party: bool = st.party.has(inst)
		var btn := _button("Di tim" if in_party else "Masukkan tim", _on_enlist.bind(inst))
		btn.disabled = in_party or st.party.size() >= 3
		v.add_child(_unit_row(inst, true, btn))
	v.add_child(_button("← Kembali ke Hub", show_hub))
	_set_body(v)

func _on_bench(i: int) -> void:
	if Core.state.party.size() > 1:
		Core.state.party.remove_at(i)
	_build_team()

func _on_enlist(inst: Dictionary) -> void:
	var st = Core.state
	if st.party.size() < 3 and not st.party.has(inst):
		inst["hp"] = inst["max_hp"]
		st.party.append(inst)
	_build_team()

# ---------- CODEX ----------
func show_codex() -> void:
	_set_loc("Codex")
	var v := _screen()
	v.add_child(_label("Codex — Field Guide", 22, Color("#eef3e9")))
	v.add_child(_label("Isi Codex sampai 100% = Bond dijamin (hook utama). Sumber: encounter, observasi skill, habitat, lore (NPC/buku).", 14, Color("#a7c0ad")))
	for sp in Core.db.raw["crypture"]["crypture"]:
		var cid := str(sp["id"])
		var pct: int = Core.codex.get_pct(cid)
		var bonded: bool = Core.codex.is_bonded(cid)
		if pct <= 0 and not bonded and sp["rarity"] != "Starter":
			v.add_child(_panel(_label("#%s · ??? — belum terdokumentasi" % cid, 13, Color("#7d917f"))))
			continue
		var c := _screen()
		var tags := ""
		if bonded:
			tags += "  ✦BONDED"
		if not bool(sp.get("bondable", true)):
			tags += "  ✦APEX (no bond)"
		c.add_child(_label("#%s · %s [%s]%s" % [cid, sp["name"], ", ".join(sp["types"]), tags], 14, Color("#eef3e9")))
		var bar := ProgressBar.new()
		bar.max_value = 100
		bar.value = pct
		bar.custom_minimum_size = Vector2(240, 12)
		bar.modulate = Color("#e7c659")
		c.add_child(bar)
		c.add_child(_label("Codex %d%% · peran %s · %s" % [pct, sp["role"], sp["rarity"]], 12, Color("#a7c0ad")))
		c.add_child(_label(sp["dex_entry"], 12, Color("#a7c0ad")))
		var used = Core.codex.sources_used.get(cid, {})
		for s in sp.get("info_sources", []):
			var mark := "✔" if used.has(s["detail"]) else "○"
			var col := Color("#6fae57") if used.has(s["detail"]) else Color("#7d917f")
			c.add_child(_label("%s [%s] %s (+%d%%)" % [mark, s["source_type"], s["detail"], int(s["codex_gain"])], 11, col))
		var chb := HBoxContainer.new()
		chb.add_theme_constant_override("separation", 12)
		var cspr := _sprite_node(cid, 64)
		cspr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chb.add_child(cspr)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chb.add_child(c)
		v.add_child(_panel(chb))
	v.add_child(_button("← Kembali", show_hub))
	_set_body(v)

# ---------- ZONA ----------
func show_zone() -> void:
	_set_loc("Hutan Luar Verdwall")
	_show_ui(false)
	_spawn_explore()

func _spawn_explore() -> void:
	_explore = ExploreZone3DScene.instantiate()
	_explore.encounter.connect(_on_encounter)
	_explore.reached_exit.connect(func(): _end_expedition("Kamu kembali ke Hub melalui jalur keluar.", []))
	_explore.go_hub.connect(func(): _end_expedition("Kamu memilih pulang.", []))
	add_child(_explore)
	if not _explore_state.is_empty():
		_explore.apply_state(_explore_state)

func _dispose_explore() -> void:
	if _explore != null and is_instance_valid(_explore):
		_explore.queue_free()
	_explore = null

func _show_ui(show: bool) -> void:
	if _bg != null: _bg.visible = show
	if _rootui != null: _rootui.visible = show

func _on_encounter(spawn) -> void:
	current_spawn = spawn
	_fighting_sid = int(spawn["sid"])
	# simpan posisi & progres eksplorasi (scene jelajah masih tampak selama flash)
	if _explore != null and is_instance_valid(_explore):
		_explore_state = _explore.get_state()
	Core.codex.add_from_source(spawn["cid"], "encounter")
	await _battle_transition(spawn)

# Transisi masuk battle: flash "Encounter!" beberapa kedip -> tutup putih -> swap -> reveal.
func _battle_transition(spawn) -> void:
	_ensure_fx()
	_fx_rect.visible = true
	_fx_rect.color = Color(1, 1, 1, 0)
	# 1) dua kedip cepat (jelajah masih terlihat di baliknya) — sensasi "Encounter!"
	for i in range(2):
		await _fade_rect(_fx_rect, 0.0, 0.6, 0.06)
		await _fade_rect(_fx_rect, 0.6, 0.0, 0.07)
	# 2) tutup penuh, lalu ganti jelajah -> battle di balik layar putih
	await _fade_rect(_fx_rect, 0.0, 1.0, 0.16)
	_dispose_explore()
	_battle3d = BattlePlay3DScene.instantiate()
	_battle3d.enemy_cid = String(spawn["cid"])
	_battle3d.enemy_lv = int(spawn["level"])
	_battle3d.animate = true
	_battle3d.battle_finished.connect(_on_battle3d_done)
	add_child(_battle3d)
	# beri beberapa frame agar panggung battle ter-render sebelum disingkap
	for i in range(3):
		await get_tree().process_frame
	# 3) singkap (kamera battle meluncur masuk via intro-nya sendiri)
	await _fade_rect(_fx_rect, 1.0, 0.0, 0.3)
	_fx_rect.visible = false

func _ensure_fx() -> void:
	if _fx_rect != null and is_instance_valid(_fx_rect):
		return
	var cl := CanvasLayer.new()
	cl.layer = 128  # di atas UI battle
	add_child(cl)
	_fx_rect = ColorRect.new()
	_fx_rect.color = Color(1, 1, 1, 0)
	_fx_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_fx_rect)

func _fade_rect(rect: ColorRect, from_a: float, to_a: float, dur: float) -> void:
	rect.color.a = from_a
	var tw := create_tween()
	tw.tween_property(rect, "color:a", to_a, dur)
	await tw.finished

func _on_battle3d_done(b) -> void:
	battle = b
	if _battle3d != null and is_instance_valid(_battle3d):
		_battle3d.queue_free()
	_battle3d = null
	# tandai musuh terkalahkan agar tak muncul lagi saat kembali menjelajah
	if (b.result == "win" or b.result == "bond") and _fighting_sid >= 0:
		var d: Array = _explore_state.get("defeated", [])
		if not d.has(_fighting_sid): d.append(_fighting_sid)
		_explore_state["defeated"] = d
	_show_ui(true)
	_resolve_battle()   # alur hasil battle (GP, misi, Bond, kembali ke zona/hub)

# ---------- BATTLE ----------
func _render_battle() -> void:
	_set_loc("Pertarungan")
	var enemy = battle.enemy
	var band = battle.hp_band(float(enemy["hp"]) / enemy["max_hp"])
	var v := _screen()
	var apex_tag := "  [APEX]" if battle.is_apex else "  [liar]"
	v.add_child(_label("Pertarungan — %s%s%s" % [enemy["name"], apex_tag, ("  🌑MURKA" if enemy["enraged"] else "")], 20, Color("#eef3e9")))

	# Lawan (HP hidden)
	var ec := _screen()
	ec.add_child(_label("Lawan — HP tersembunyi", 12, Color("#a7c0ad")))
	ec.add_child(_label("%s  Lv%d  [%s]" % [enemy["name"], enemy["level"], ", ".join(enemy["types"])], 15, Color("#eef3e9")))
	var ebar := ProgressBar.new()
	ebar.max_value = enemy["max_hp"]
	ebar.value = max(0, enemy["hp"])
	ebar.show_percentage = false
	ebar.custom_minimum_size = Vector2(260, 14)
	ec.add_child(ebar)
	var cond := "Kondisi: %s" % band["label"]
	if not battle.is_apex:
		cond += "  ·  Codex %d%% → Bond %d%%" % [Core.codex.get_pct(enemy["cid"]), Core.codex.bond_rate(enemy["cid"])]
	ec.add_child(_label(cond, 12, Color("#a7c0ad")))
	ec.add_child(_label(enemy["species"]["dex_entry"], 12, Color("#7d917f")))
	var ehb := HBoxContainer.new()
	ehb.add_theme_constant_override("separation", 14)
	var espr := _sprite_node(enemy["cid"], 112)
	espr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ehb.add_child(espr)
	ec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ehb.add_child(ec)
	v.add_child(_panel(ehb))

	# Tim
	v.add_child(_label("Tim Seeker", 13, Color("#a7c0ad")))
	for p in Core.state.party:
		var row := _unit_row(p)
		if battle.pending == p:
			row.modulate = Color("#e7c659")
		v.add_child(row)

	# Perintah / log
	v.add_child(_label("Perintah", 13, Color("#a7c0ad")))
	var cmd := _screen()
	if battle.over:
		cmd.add_child(_button("Lanjut →", _resolve_battle))
	elif battle.pending != null:
		var u = battle.pending
		cmd.add_child(_label("Giliran: %s (%s)" % [u["name"], u["role"]], 13, Color("#eef3e9")))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		for mv in u["moves"]:
			var t: String = mv["type"] if mv["type"] != "Normal" else "basic"
			grid.add_child(_button("%s (%s)" % [mv["name"], t], _do_move.bind(mv)))
		var pot := _button("🧪 Potion%s" % ("" if battle.seeker_cd == 0 else " (cd %d)" % battle.seeker_cd), _do_seeker.bind("potion"))
		pot.disabled = battle.seeker_cd > 0
		grid.add_child(pot)
		var scan := _button("🔍 Scan", _do_seeker.bind("scan"))
		scan.disabled = battle.seeker_cd > 0
		grid.add_child(scan)
		if not battle.is_apex:
			grid.add_child(_button("🤝 Bond (%d%%)" % Core.codex.bond_rate(enemy["cid"]), _do_seeker.bind("bond")))
		grid.add_child(_button("🏃 Lari", _do_flee))
		cmd.add_child(grid)
		cmd.add_child(_label("Aksi Seeker punya cooldown — bukan tombol menang. Tank menahan, support menyembuhkan, attacker memukul.", 11, Color("#7d917f")))
	v.add_child(_panel(cmd))

	v.add_child(_label("Catatan Pertempuran", 13, Color("#a7c0ad")))
	var log_text := ""
	var lines = battle.log_lines
	var startn = max(0, lines.size() - 12)
	for i in range(startn, lines.size()):
		log_text += lines[i] + "\n"
	v.add_child(_panel(_label(log_text, 12, Color("#cfe0d0"))))
	_set_body(v)

func _do_move(mv: Dictionary) -> void:
	battle.player_move(mv)
	_render_battle()

func _do_seeker(kind: String) -> void:
	battle.seeker_action(kind)
	_render_battle()

func _do_flee() -> void:
	battle.flee()
	_render_battle()

func _resolve_battle() -> void:
	var events = Core.state.on_battle_result(battle)
	# (musuh terkalahkan sudah ditandai di _explore_state oleh _on_battle3d_done)
	var res = battle.result
	if res == "lose":
		_end_expedition("Tim tumbang — kamu dipulihkan di Hub.", events)
		return
	if battle.is_apex and res == "win":
		_apex_victory(events)
		return
	# ringkasan lalu kembali ke zona
	var v := _screen()
	var title := "✨ Bond Berhasil" if res == "bond" else ("Lolos" if res == "flee" else "Menang")
	v.add_child(_label(title, 22, Color("#eef3e9")))
	var lines = battle.log_lines
	var tail := ""
	for i in range(max(0, lines.size() - 6), lines.size()):
		tail += lines[i] + "\n"
	v.add_child(_panel(_label(tail, 12, Color("#cfe0d0"))))
	for e in events:
		v.add_child(_label("✅ " + e, 13, Color("#6fae57")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_button("↩ Lanjut menjelajah", _back_to_zone))
	row.add_child(_button("Pulang ke Hub", func(): _end_expedition("Kamu kembali ke Hub.", [])))
	v.add_child(row)
	_set_body(v)

func _back_to_zone() -> void:
	# kembali menjelajah: bangun ulang dunia 3D dari state (posisi & musuh terkalahkan terjaga)
	_set_loc("Hutan Luar Verdwall")
	_show_ui(false)
	_spawn_explore()

func _apex_victory(events: Array) -> void:
	_dispose_explore()
	_explore_state = {}; _fighting_sid = -1
	current_spawn = null
	_set_loc("Jantung Verdwall")
	var v := _screen()
	v.add_child(_label("🌳 Jantung Verdwall — Story Thread Tertutup", 22, Color("#eef3e9")))
	v.add_child(_label("Eldergrove tidak tumbang seperti makhluk biasa. Ia melambat, mengakui kehadiranmu, lalu surut ke akar dunia. Kamu tak menangkapnya — kamu MEMAHAMINYA, lalu MELEWATINYA. Di kejauhan, nama Luvirel dan Merlyon berbisik: Verdwall hanyalah satu daun dari pohon yang jauh lebih besar.", 14, Color("#a7c0ad")))
	for e in events:
		v.add_child(_label("✅ " + e, 13, Color("#6fae57")))
	v.add_child(_label("Avalon terbuka setelah seluruh region ditaklukkan — endgame di luar slice ini.", 12, Color("#7d917f")))
	v.add_child(_button("← Kembali ke Hub", show_hub))
	_set_body(v)

func _end_expedition(note: String, events: Array) -> void:
	_dispose_explore()
	_explore_state = {}; _fighting_sid = -1
	current_spawn = null
	for p in Core.state.party:
		p["hp"] = p["max_hp"]
		p["status"] = ""
		p["stat_stages"] = {"atk": 0, "def": 0, "sp_atk": 0, "sp_def": 0, "speed": 0}
		p["enraged"] = false
		p["taunt"] = 0
	_set_loc("Outpost Verdwall (Hub)")
	var st = Core.state
	var v := _screen()
	v.add_child(_label("Lapor ke Guild", 22, Color("#eef3e9")))
	v.add_child(_label(note, 14, Color("#a7c0ad")))
	v.add_child(_panel(_label("Rank %d · %s — GP %d" % [st.rank, st.rank_info(st.rank)["name"], st.gp], 13, Color("#eef3e9"))))
	for e in events:
		v.add_child(_label("✅ " + e, 13, Color("#6fae57")))
	v.add_child(_button("Masuk Hub →", show_hub))
	_set_body(v)
