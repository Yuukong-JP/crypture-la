# BattlePlay3D.gd — battle yang BISA DIMAINKAN: panggung 3D (3/4) + UI overlay,
# digerakkan oleh engine Battle yang sudah teruji. Seeker diwakili di UI (aksi), bukan di panggung.
extends Node3D

const PARTY_X := [-2.4, 0.0, 2.4]
const ENEMY_CID := "015"  # Mosswhim
const ENEMY_LV := 10

var battle
var cam: Camera3D
var spr := {}            # instance uid -> Sprite3D
# UI
var ui_enemy: Label
var ui_party: VBoxContainer
var ui_cmd: VBoxContainer
var ui_log: RichTextLabel

func _ready() -> void:
	_build_stage()
	var party: Array = Core.state.party
	for p in party:                      # pulihkan utk demo
		p["hp"] = p["max_hp"]; p["status"] = ""; p["enraged"] = false; p["taunt"] = 0
		p["stat_stages"] = {"atk": 0, "def": 0, "sp_atk": 0, "sp_def": 0, "speed": 0}
	var enemy: Dictionary = Core.db.make_instance(ENEMY_CID, ENEMY_LV, true)
	_spawn(Core.db.sprite_for(ENEMY_CID), Vector3(0, 0, -6.5), 3.0, enemy["uid"])
	for i in range(party.size()):
		_spawn(Core.db.sprite_back_for(party[i]["cid"]), Vector3(PARTY_X[i], 0, 2.6), 1.9, party[i]["uid"])
	battle = Core.new_battle(party, enemy)
	_build_ui()
	_refresh()

# ---------- panggung 3D ----------
func _build_stage() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#15241d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#5d7e69")
	env.ambient_light_energy = 0.65
	env.fog_enabled = true
	env.fog_light_color = Color("#2a4a3c")
	env.fog_density = 0.05
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.18
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.1
	env.adjustment_saturation = 1.15
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -34, 0)
	sun.light_energy = 1.2; sun.light_color = Color("#ffe7c4"); sun.shadow_enabled = true
	add_child(sun)

	_disc(Vector3(0, 0, 3.2), 4.2, Color("#3f6b44"))
	_disc(Vector3(0, 0, -6.5), 3.6, Color("#4a6552"))
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(40, 40); ground.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color("#2c4a35")
	ground.material_override = gm; ground.position.y = -0.02; add_child(ground)

	cam = Camera3D.new(); cam.fov = 52; add_child(cam)
	# sudut pilihan owner
	var target := Vector3(-0.4, 1.0, -1.6)
	var yr := deg_to_rad(25.0); var pr := deg_to_rad(11.6); var dist := 8.6
	var dir := Vector3(sin(yr) * cos(pr), sin(pr), cos(yr) * cos(pr))
	cam.position = target + dir * dist
	cam.look_at(target, Vector3.UP)

func _disc(pos: Vector3, radius: float, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new(); cyl.top_radius = radius; cyl.bottom_radius = radius; cyl.height = 0.18
	mi.mesh = cyl
	var m := StandardMaterial3D.new(); m.albedo_color = col
	mi.material_override = m; mi.position = pos; add_child(mi)

func _spawn(tex: Texture2D, pos: Vector3, height: float, uid: int) -> void:
	var s := Sprite3D.new()
	s.texture = tex
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = true
	s.pixel_size = height / float(tex.get_height())
	s.position = pos + Vector3(0, height * 0.5, 0)
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(s)
	spr[uid] = s

# ---------- UI overlay ----------
func _sb_panel() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.13, 0.10, 0.84)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	sb.border_color = Color(0.25, 0.40, 0.32)
	sb.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", sb)
	return p

func _lbl(t: String, sz := 14, col := Color("#eef3e9")) -> Label:
	var l := Label.new(); l.text = t
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	return l

func _btn(t: String, cb: Callable) -> Button:
	var b := Button.new(); b.text = t; b.pressed.connect(cb); return b

func _spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func _build_ui() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for m in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + m, 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)

	# baris atas: [kondisi lawan tengah] ... [log kanan]
	var top := HBoxContainer.new(); top.add_theme_constant_override("separation", 10)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	top.add_child(_spacer())
	var ep := _sb_panel(); var ev := VBoxContainer.new(); ep.add_child(ev)
	ui_enemy = _lbl("", 15); ev.add_child(ui_enemy); top.add_child(ep)
	top.add_child(_spacer())
	var lp := _sb_panel()
	ui_log = RichTextLabel.new(); ui_log.fit_content = true
	ui_log.custom_minimum_size = Vector2(290, 92)
	ui_log.add_theme_font_size_override("normal_font_size", 12)
	lp.add_child(ui_log); top.add_child(lp)

	col.add_child(_spacer_v())  # dorong baris bawah ke bawah

	# baris bawah: [HP party kiri] ... [perintah kanan]
	var bot := HBoxContainer.new(); bot.add_theme_constant_override("separation", 10)
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(bot)
	var pp := _sb_panel(); ui_party = VBoxContainer.new(); pp.add_child(ui_party); bot.add_child(pp)
	bot.add_child(_spacer())
	var cp := _sb_panel()
	ui_cmd = VBoxContainer.new(); ui_cmd.add_theme_constant_override("separation", 6)
	ui_cmd.custom_minimum_size = Vector2(320, 0)
	cp.add_child(ui_cmd); bot.add_child(cp)

func _spacer_v() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func _refresh() -> void:
	var enemy = battle.enemy
	# sprite: pudar yg tumbang
	for uid in spr.keys():
		var node: Sprite3D = spr[uid]
		var inst = _find_unit(uid)
		if inst != null and inst["hp"] <= 0:
			node.modulate = Color(0.3, 0.3, 0.3, 0.25)
		elif battle.pending != null and inst != null and inst["uid"] == battle.pending["uid"]:
			node.modulate = Color(1.25, 1.25, 1.25, 1)   # giliran aktif → lebih terang
		else:
			node.modulate = Color(1, 1, 1, 1)

	# kondisi lawan (HP TERSEMBUNYI)
	var band = battle.hp_band(float(enemy["hp"]) / enemy["max_hp"])
	var et := "%s  Lv%d  —  %s" % [enemy["name"], enemy["level"], band["label"]]
	if not battle.is_apex:
		et += "   ·   Codex %d%% → Bond %d%%" % [Core.codex.get_pct(enemy["cid"]), Core.codex.bond_rate(enemy["cid"])]
	if enemy["enraged"]:
		et += "   🌑MURKA"
	ui_enemy.text = et

	# HP party
	for c in ui_party.get_children():
		c.queue_free()
	for p in Core.state.party:
		var frac: float = float(p["hp"]) / float(p["max_hp"])
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 8)
		var nm := _lbl("%s" % p["name"], 13)
		nm.custom_minimum_size = Vector2(72, 0)
		row.add_child(nm)
		var bar := ProgressBar.new()
		bar.max_value = p["max_hp"]; bar.value = max(0, p["hp"]); bar.show_percentage = false
		bar.custom_minimum_size = Vector2(150, 12)
		bar.modulate = Color("#e0683b") if frac < 0.4 else Color("#6fae57")
		row.add_child(bar)
		row.add_child(_lbl("%d/%d%s" % [max(0, int(p["hp"])), p["max_hp"], "  🔥" if p["status"] == "burn" else ""], 11, Color("#a7c0ad")))
		ui_party.add_child(row)

	# log
	var s := ""
	var lines = battle.log_lines
	for i in range(max(0, lines.size() - 6), lines.size()):
		s += lines[i] + "\n"
	ui_log.text = s

	_build_cmd()

func _build_cmd() -> void:
	for c in ui_cmd.get_children():
		c.queue_free()
	if battle.over:
		var res: String = battle.result
		var title := "✨ Bond!" if res == "bond" else ("🏆 Menang!" if res == "win" else ("🏃 Lolos" if res == "flee" else "💤 Kalah"))
		ui_cmd.add_child(_lbl(title, 18, Color("#e7c659")))
		ui_cmd.add_child(_btn("Main lagi", func(): get_tree().reload_current_scene()))
		return
	var u = battle.pending
	if u == null:
		ui_cmd.add_child(_lbl("…", 13))
		return
	ui_cmd.add_child(_lbl("Giliran: %s (%s)" % [u["name"], u["role"]], 13, Color("#eef3e9")))
	var grid := GridContainer.new(); grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6); grid.add_theme_constant_override("v_separation", 6)
	for mv in u["moves"]:
		var t: String = mv["type"] if mv["type"] != "Normal" else "basic"
		grid.add_child(_btn("%s (%s)" % [mv["name"], t], _ui_move.bind(mv)))
	var pot := _btn("🧪 Potion%s" % ("" if battle.seeker_cd == 0 else " (cd %d)" % battle.seeker_cd), _ui_seeker.bind("potion"))
	pot.disabled = battle.seeker_cd > 0
	grid.add_child(pot)
	var scan := _btn("🔍 Scan", _ui_seeker.bind("scan")); scan.disabled = battle.seeker_cd > 0
	grid.add_child(scan)
	if not battle.is_apex:
		grid.add_child(_btn("🤝 Bond (%d%%)" % Core.codex.bond_rate(battle.enemy["cid"]), _ui_seeker.bind("bond")))
	grid.add_child(_btn("🏃 Lari", _ui_flee))
	ui_cmd.add_child(grid)

func _ui_move(mv: Dictionary) -> void:
	battle.player_move(mv); _refresh()
func _ui_seeker(kind: String) -> void:
	battle.seeker_action(kind); _refresh()
func _ui_flee() -> void:
	battle.flee(); _refresh()

func _find_unit(uid: int):
	if battle.enemy["uid"] == uid:
		return battle.enemy
	for p in Core.state.party:
		if p["uid"] == uid:
			return p
	return null
