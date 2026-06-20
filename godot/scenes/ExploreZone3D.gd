# ExploreZone3D.gd — eksplorasi 2.5D (HD-2D): jalan di dunia 3D miring, Crypture sebagai
# billboard, titik lore & pintu keluar. Memberi sinyal ke Main. State bisa disimpan/dipulihkan
# agar posisi & musuh-yang-sudah-dikalahkan terjaga lintas battle.
extends Node3D

signal encounter(spawn)
signal reached_exit()
signal go_hub()
signal lore_collected(text)

const GRID := 1.8
const MOVE_SPEED := 5.5
const NEAR := 1.35

var player: Sprite3D
var cam: Camera3D
var creatures: Array = []   # {sid, cid, node, alive, behavior, pos}
var lores: Array = []       # {lid, for, type, text, name, node, used, pos}
var exit_pos: Vector3
var hud_msg: Label
var _state_player := Vector3(0, 0, 0)
var _player_base_y := 1.0

func _ready() -> void:
	_build_world()
	_build_hud()

func _grid_to_world(gx: int, gy: int) -> Vector3:
	var sz: Dictionary = Core.db.world["zone"]["size"]
	return Vector3((gx - int(sz["w"]) / 2.0) * GRID, 0, (gy - int(sz["h"]) / 2.0) * GRID)

func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#173026")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#5a7a66"); env.ambient_light_energy = 0.6
	env.fog_enabled = true; env.fog_light_color = Color("#2f5142"); env.fog_density = 0.035
	env.glow_enabled = true; env.glow_intensity = 0.5; env.glow_bloom = 0.15
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.adjustment_enabled = true; env.adjustment_contrast = 1.08; env.adjustment_saturation = 1.12
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -38, 0); sun.light_energy = 1.15
	sun.light_color = Color("#ffe6c2"); sun.shadow_enabled = true; add_child(sun)

	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(70, 50); ground.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color("#3c6b40"); ground.material_override = gm
	add_child(ground)

	var tree_tex: Texture2D = load("res://assets/world/tree.png")
	for s in [Vector2(-12, -9), Vector2(-8, 5), Vector2(7, -11), Vector2(12, -4), Vector2(-14, 3),
			  Vector2(10, 7), Vector2(2, -15), Vector2(-4, 10), Vector2(15, 1), Vector2(-15, -3)]:
		_billboard(tree_tex, Vector3(s.x, 0, s.y), 3.4, true)

	var zone: Dictionary = Core.db.world["zone"]
	var sid := 0
	for sp in zone["spawns"]:
		var cid := String(sp["cid"])
		var tex: Texture2D = Core.db.sprite_for(cid)
		var scale := float(Core.db.species[cid].get("display_scale", 1.0))
		var pos := _grid_to_world(int(sp["x"]), int(sp["y"]))
		var node: Sprite3D = _billboard(tex, pos, 1.5 * scale, true) if tex != null else null
		creatures.append({"sid": sid, "cid": cid, "node": node, "alive": true,
			"behavior": String(sp.get("behavior", "still")), "pos": pos, "level": int(sp["level"]),
			"home": pos, "base_y": (node.position.y if node != null else 0.0),
			"phase": sid * 1.3, "wdir": randf() * TAU})
		sid += 1

	var lid := 0
	for lp in zone["lore_points"]:
		var pos := _grid_to_world(int(lp["x"]), int(lp["y"]))
		var n := _spark(pos)
		lores.append({"lid": lid, "for": String(lp["for"]), "type": String(lp["source_type"]),
			"text": String(lp["text"]), "name": String(lp["name"]), "node": n, "used": false, "pos": pos})
		lid += 1

	exit_pos = _grid_to_world(int(zone["exit"]["x"]), int(zone["exit"]["y"]))
	var ex := Label3D.new()
	ex.text = "▼ EXIT"; ex.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ex.font_size = 64; ex.outline_size = 16; ex.modulate = Color("#e7c659")
	ex.position = exit_pos + Vector3(0, 1.4, 0); add_child(ex)

	player = _billboard(load("res://assets/world/seeker.png"), _grid_to_world(7, 9), 2.0, true)
	_player_base_y = player.position.y
	_state_player = player.position

	cam = Camera3D.new(); cam.fov = 55; add_child(cam); cam.make_current()
	_update_cam()

func _spark(pos: Vector3) -> Node3D:
	var l := Label3D.new()
	l.text = "✨"; l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 56; l.modulate = Color("#f3df9a")
	l.position = pos + Vector3(0, 1.0, 0); add_child(l)
	return l

func _billboard(tex: Texture2D, pos: Vector3, height: float, shadow: bool) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = true
	s.pixel_size = height / float(tex.get_height())
	s.position = pos + Vector3(0, height * 0.5, 0)
	if shadow: s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(s)
	return s

func _update_cam() -> void:
	var p := player.position
	cam.position = p + Vector3(1.5, 6.8, 8.0)   # 3/4 dari belakang-samping
	cam.look_at(p + Vector3(0, 0.6, 0), Vector3.UP)

func _build_hud() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	hud_msg = Label.new()
	hud_msg.text = "WASD / panah untuk jelajah  ·  dekati Crypture untuk battle  ·  ke EXIT untuk pulang"
	hud_msg.add_theme_font_size_override("font_size", 14)
	hud_msg.add_theme_color_override("font_color", Color("#eef3e9"))
	hud_msg.position = Vector2(16, 12)
	root.add_child(hud_msg)
	var btn := Button.new(); btn.text = "↩ Pulang ke Hub"
	btn.pressed.connect(func(): go_hub.emit())
	btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 12)
	root.add_child(btn)

func _process(delta: float) -> void:
	if player == null:
		return
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): dir.z -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): dir.z += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1
	if dir != Vector3.ZERO:
		var np: Vector3 = player.position + dir.normalized() * MOVE_SPEED * delta
		np.x = clampf(np.x, -16, 16); np.z = clampf(np.z, -12, 12)
		player.position = Vector3(np.x, _player_base_y, np.z)
		_state_player = player.position
		_update_cam()
		_check_proximity()
	_animate_world(delta)

# Goyang-idle + perilaku liar (wander/flee) — bikin dunia terasa hidup.
func _animate_world(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var ppos := Vector2(player.position.x, player.position.z)
	for c in creatures:
		if not c["alive"] or c["node"] == null:
			continue
		var n: Sprite3D = c["node"]
		var pos2 := Vector2(n.position.x, n.position.z)
		var home: Vector3 = c["home"]
		match c["behavior"]:
			"wander":
				c["wdir"] += (randf() - 0.5) * delta * 2.5
				var nxt := pos2 + Vector2(cos(c["wdir"]), sin(c["wdir"])) * 0.8 * delta
				if nxt.distance_to(Vector2(home.x, home.z)) > 2.4:
					c["wdir"] += PI
				else:
					pos2 = nxt
			"flee":
				if pos2.distance_to(ppos) < 4.0:
					pos2 += (pos2 - ppos).normalized() * 2.4 * delta
					pos2.x = clampf(pos2.x, -16, 16); pos2.y = clampf(pos2.y, -12, 12)
		var bob := sin(t * 2.2 + c["phase"]) * 0.09
		n.position = Vector3(pos2.x, c["base_y"] + bob, pos2.y)
		c["pos"] = Vector3(pos2.x, 0, pos2.y)
	# pemain ikut bergoyang halus
	player.position.y = _player_base_y + sin(t * 3.0) * 0.05

func _check_proximity() -> void:
	var pp := Vector2(player.position.x, player.position.z)
	# lore
	for l in lores:
		if l["used"]: continue
		if pp.distance_to(Vector2(l["pos"].x, l["pos"].z)) < NEAR:
			l["used"] = true
			if l["node"] != null: l["node"].visible = false
			var g: int = Core.codex.add_from_source(l["for"], l["type"])
			var nm := String(Core.db.species[l["for"]]["name"])
			hud_msg.text = "🌿 %s: %s %s" % [l["name"], l["text"], ("Codex %s +%d%%." % [nm, g]) if g > 0 else ""]
			lore_collected.emit(hud_msg.text)
	# exit
	if pp.distance_to(Vector2(exit_pos.x, exit_pos.z)) < NEAR:
		reached_exit.emit(); return
	# creatures
	for c in creatures:
		if not c["alive"]: continue
		if pp.distance_to(Vector2(c["pos"].x, c["pos"].z)) < NEAR:
			encounter.emit({"sid": c["sid"], "cid": c["cid"], "level": c["level"]})
			return

# ---- state persisten (agar posisi & musuh terkalahkan terjaga lintas battle) ----
func get_state() -> Dictionary:
	var defeated := []
	for c in creatures:
		if not c["alive"]: defeated.append(c["sid"])
	var used := []
	for l in lores:
		if l["used"]: used.append(l["lid"])
	return {"player": _state_player, "defeated": defeated, "used_lore": used}

func apply_state(st: Dictionary) -> void:
	if st.is_empty(): return
	if st.has("player"):
		player.position = st["player"]; _state_player = st["player"]; _update_cam()
	for sid in st.get("defeated", []):
		for c in creatures:
			if c["sid"] == sid:
				c["alive"] = false
				if c["node"] != null: c["node"].queue_free()
	for lid in st.get("used_lore", []):
		for l in lores:
			if l["lid"] == lid:
				l["used"] = true
				if l["node"] != null: l["node"].visible = false
