# Main.gd — screen manager + UI (dibangun via kode agar .tscn minimal & tahan error).
# Loop: intro -> hub -> zona -> battle -> report. Memakai autoload Core (db/codex/state).
extends Control

const ZoneViewScene := preload("res://scenes/ZoneView.gd")

var top_rank: Label
var top_gp: Label
var top_loc: Label
var body: MarginContainer

var battle            # Battle aktif
var zone_view         # ZoneView aktif (di-detach dari tree saat battle agar tak ter-free)
var zone_msg: Label   # label status zona (di-update saat lore terkumpul)
var current_spawn     # spawn yang sedang ditempur

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#1b2a22")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	# Top bar
	var bar := PanelContainer.new()
	var barbox := HBoxContainer.new()
	barbox.add_theme_constant_override("separation", 18)
	var brand := _label("CRYPTURE · Lost Avalon — Verdwall slice", 15, Color("#e7c659"), false)
	top_rank = _label("Rank —", 13, null, false)
	top_gp = _label("GP 0", 13, null, false)
	top_loc = _label("—", 13, null, false)
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

# ---------- HUB ----------
func show_hub() -> void:
	_set_loc("Outpost Verdwall (Hub)")
	var st = Core.state
	var v := _screen()
	v.add_child(_label("Outpost Verdwall", 22, Color("#eef3e9")))
	v.add_child(_label("Pilih ekspedisi, gali petunjuk Codex dari penduduk, lalu berangkat. Pulang, lapor, dapat Guild Points, naik Rank.", 14, Color("#a7c0ad")))

	# Tim aktif
	var team := _screen()
	team.add_child(_label("Tim Aktif (maks 3)", 13, Color("#a7c0ad")))
	for p in st.party:
		team.add_child(_unit_row(p))
	var teambtns := HBoxContainer.new()
	teambtns.add_theme_constant_override("separation", 8)
	teambtns.add_child(_button("Kelola Tim", show_team))
	teambtns.add_child(_button("Buka Codex", show_codex))
	team.add_child(teambtns)
	v.add_child(_panel(team))

	# Papan ekspedisi
	var mis := _screen()
	mis.add_child(_label("Papan Ekspedisi", 13, Color("#a7c0ad")))
	for m in st.active_missions():
		mis.add_child(_mission_row(m, true))
	for m in st.available_missions():
		mis.add_child(_mission_row(m, false))
	if st.active_missions().is_empty() and st.available_missions().is_empty():
		mis.add_child(_label("Tidak ada kontrak tersedia.", 12, Color("#a7c0ad")))
	v.add_child(_panel(mis))

	# Interaksi hub
	var hubi := _screen()
	hubi.add_child(_label("Penduduk & Arsip Hub — sumber lore Codex", 13, Color("#a7c0ad")))
	hubi.add_child(_label("Ngobrol & periksa buku mengisi Codex Crypture langka (eksplorasi sosial = progres mekanis).", 12, Color("#a7c0ad")))
	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 8)
	for it in Core.db.world["hub"]["interactions"]:
		var icon := "📖 " if it["kind"] == "book" else "💬 "
		hrow.add_child(_button(icon + it["name"], _on_interact.bind(it)))
	var hwrap := ScrollContainer.new()
	hwrap.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hwrap.custom_minimum_size = Vector2(0, 48)
	hwrap.add_child(hrow)
	hubi.add_child(hwrap)
	v.add_child(_panel(hubi))

	v.add_child(_button("⛺ Berangkat ke Hutan Luar Verdwall →", show_zone))
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
	show_hub()

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
	v.add_child(_button("Kembali", show_hub))
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
	var v := _screen()
	v.add_child(_label("Hutan Luar Verdwall", 20, Color("#eef3e9")))
	zone_msg = _label("WASD / panah untuk bergerak. Dekati Crypture untuk encounter. EXIT = pulang.", 12, Color("#a7c0ad"))
	v.add_child(zone_msg)
	zone_view = ZoneViewScene.new()
	zone_view.setup(Core.db)
	zone_view.encounter.connect(_on_encounter)
	zone_view.reached_exit.connect(func(): _end_expedition("Kamu kembali ke Hub melalui jalur keluar.", []))
	zone_view.lore_collected.connect(_on_lore)
	v.add_child(zone_view)
	v.add_child(_button("↩ Paksa pulang ke Hub", func(): _end_expedition("Kamu memilih pulang.", [])))
	v.add_child(_label("Crypture liar lebih kuat dari versi ter-Bond (wild_multiplier).", 11, Color("#7d917f")))
	_set_body(v)
	if zone_view.is_inside_tree():
		zone_view.grab_focus()

func _on_lore(t: String) -> void:
	if is_instance_valid(zone_msg):
		zone_msg.text = t

func _dispose_zone() -> void:
	if zone_view != null and is_instance_valid(zone_view):
		if zone_view.get_parent() != null:
			zone_view.get_parent().remove_child(zone_view)
		zone_view.queue_free()
	zone_view = null

func _on_encounter(spawn) -> void:
	# lepas zona dari tree agar tak ikut ter-free saat layar battle dibangun
	if zone_view != null and is_instance_valid(zone_view) and zone_view.get_parent() != null:
		zone_view.get_parent().remove_child(zone_view)
	current_spawn = spawn
	var sp = Core.db.species[spawn["cid"]]
	var is_apex := not bool(sp.get("bondable", true))
	var enemy: Dictionary = Core.db.make_instance(spawn["cid"], int(spawn["level"]), not is_apex)
	Core.codex.add_from_source(spawn["cid"], "encounter")
	battle = Core.new_battle(Core.state.party, enemy)
	_render_battle()

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
	if current_spawn != null and (battle.result == "win" or battle.result == "bond") and zone_view != null:
		zone_view.mark_defeated(current_spawn)
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
	_set_loc("Hutan Luar Verdwall")
	var v := _screen()
	v.add_child(_label("Hutan Luar Verdwall", 20, Color("#eef3e9")))
	zone_msg = _label("Lanjut menjelajah. EXIT = pulang.", 12, Color("#a7c0ad"))
	v.add_child(zone_msg)
	# pakai zone_view yang sama (state terjaga); sudah di-detach saat encounter
	if zone_view.get_parent() != null:
		zone_view.get_parent().remove_child(zone_view)
	v.add_child(zone_view)
	v.add_child(_button("↩ Paksa pulang ke Hub", func(): _end_expedition("Kamu memilih pulang.", [])))
	_set_body(v)
	if zone_view.is_inside_tree():
		zone_view.grab_focus()

func _apex_victory(events: Array) -> void:
	_dispose_zone()
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
	_dispose_zone()
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
