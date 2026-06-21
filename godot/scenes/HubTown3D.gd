# HubTown3D.gd — Hub sebagai KOTA 3D yang bisa dijelajahi (vibe gathering hub Monster Hunter).
# Seeker jalan (WASD) di Outpost Verdwall; dekati "stasiun" lalu tekan E/Enter untuk membuka:
#   📋 Papan Ekspedisi · ⛺ Tenda Tim · 📖 Arsip Codex · 💬 Balai Warga · 🚪 Gerbang Hutan (berangkat).
# Memberi sinyal ke Main; posisi pemain bisa disimpan/dipulihkan (state) lintas menu.
extends Node3D

signal station(kind)        # kind: "board" | "team" | "codex" | "talk" | "depart"

const MOVE_SPEED := 5.5
const NEAR := 1.7

var player: Sprite3D
var _ptex := {}            # tekstur arah seeker (front/back/left/right)
var _facing := "front"
var cam: Camera3D
var stations: Array = []     # {kind, name, pos, label}
var _near = null             # stasiun terdekat dalam jangkauan
var hud_msg: Label
var prompt: Label
var _lanterns: Array = []
var _player_base_y := 1.0
var _state_player := Vector3(0, 0, 6)

func _ready() -> void:
	_build_town()
	_build_hud()

# ---------------- dunia ----------------
func _build_town() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#1a1622")            # langit senja keunguan
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#6b5f72"); env.ambient_light_energy = 0.7
	env.fog_enabled = true; env.fog_light_color = Color("#3a2f42"); env.fog_density = 0.03
	# glow halus, bloom mati, threshold tinggi -> lentera bercahaya tapi tak membakar layar
	env.glow_enabled = true; env.glow_intensity = 0.3; env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.25
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.adjustment_enabled = true; env.adjustment_contrast = 1.06; env.adjustment_saturation = 1.14
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)

	var sun := DirectionalLight3D.new()        # cahaya senja hangat dari samping
	sun.rotation_degrees = Vector3(-28, -48, 0); sun.light_energy = 0.9
	sun.light_color = Color("#ffcaa0"); sun.shadow_enabled = true; add_child(sun)

	# tanah rumput + jalan setapak + plaza batu
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(60, 46); ground.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color("#37532f"); ground.material_override = gm
	ground.position.y = -0.02; add_child(ground)
	_disc(Vector3(0, 0, 2), 6.0, Color("#6a5b46"), 0.12)        # plaza
	_path(Vector3(0, 0, 2), Vector3(0, 0, -9), 2.4)            # jalan ke gerbang

	# rumah-rumah di pinggir kota (dinding + atap pelana + pintu)
	_house(Vector3(-10, 0, -4), Vector2(4.5, 3.4), Color("#8a6b4a"), Color("#7a3b32"))
	_house(Vector3(10, 0, -5), Vector2(5.0, 3.8), Color("#7d6447"), Color("#6f4a2e"))
	_house(Vector3(-11, 0, 4), Vector2(4.0, 3.0), Color("#8a6b4a"), Color("#5d6e44"))
	_house(Vector3(11, 0, 5), Vector2(4.5, 3.2), Color("#7d6447"), Color("#7a3b32"))
	_house(Vector3(-3, 0, -8), Vector2(3.6, 2.8), Color("#86694a"), Color("#6f4a2e"))

	# pepohonan di sudut sebagai pembatas
	var tree_tex: Texture2D = load("res://assets/world/tree.png")
	for s in [Vector2(-14, -8), Vector2(14, -8), Vector2(-15, 8), Vector2(15, 8), Vector2(-15, 0), Vector2(15, 1)]:
		_billboard(tree_tex, Vector3(s.x, 0, s.y), 3.6)

	# lentera di sekitar plaza (cahaya hangat berkedip)
	for s in [Vector2(-4, -1), Vector2(4, -1), Vector2(-4, 5), Vector2(4, 5)]:
		_lantern(Vector3(s.x, 0, s.y))

	# stasiun interaksi
	_add_station("board", "📋", "Papan Ekspedisi", Vector3(-5.5, 0, -1), Color("#e7c659"))
	_add_station("team", "⛺", "Tenda Tim", Vector3(5.5, 0, -1), Color("#9ed27f"))
	_add_station("codex", "📖", "Arsip Codex", Vector3(-5.5, 0, 5), Color("#8fb6d8"))
	_add_station("talk", "💬", "Balai Warga", Vector3(5.5, 0, 5), Color("#e0a0c0"))
	_gate(Vector3(0, 0, -9))    # gerbang = stasiun "depart"

	# warga kota (figur diam, sekadar menghidupkan) — pakai sprite seeker dimodulasi
	var seeker_tex: Texture2D = load("res://assets/world/seeker.png")
	for item in [[Vector3(-3.4, 0, 1.2), Color("#cfd6e0")], [Vector3(3.2, 0, 6.4), Color("#d8c2a0")],
				 [Vector3(7.4, 0, 1.0), Color("#c0d0b0")]]:
		var npc := _billboard(seeker_tex, item[0], 1.9)
		npc.modulate = item[1]

	_ptex = {
		"front": load("res://assets/world/seeker.png"),
		"back": load("res://assets/world/seeker_back.png"),
		"left": load("res://assets/world/seeker_left.png"),
		"right": load("res://assets/world/seeker_right.png"),
	}
	player = _billboard(_ptex["front"], Vector3(0, 0, 6), 2.0)
	_player_base_y = player.position.y
	_state_player = player.position

	cam = Camera3D.new(); cam.fov = 55; add_child(cam); cam.make_current()
	_update_cam()

func _disc(pos: Vector3, radius: float, col: Color, h := 0.1) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new(); cyl.top_radius = radius; cyl.bottom_radius = radius; cyl.height = h
	mi.mesh = cyl
	var m := StandardMaterial3D.new(); m.albedo_color = col
	mi.material_override = m; mi.position = pos + Vector3(0, h * 0.5, 0); add_child(mi)

func _path(a: Vector3, b: Vector3, w: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var len := a.distance_to(b)
	bm.size = Vector3(w, 0.08, len); mi.mesh = bm
	var m := StandardMaterial3D.new(); m.albedo_color = Color("#6a5b46"); mi.material_override = m
	mi.position = (a + b) * 0.5 + Vector3(0, 0.04, 0); add_child(mi)

func _house(pos: Vector3, size: Vector2, wall: Color, roof: Color) -> void:
	var wh := size.y
	# dinding
	var wall_mi := MeshInstance3D.new()
	var wbm := BoxMesh.new(); wbm.size = Vector3(size.x, wh, size.x * 0.85); wall_mi.mesh = wbm
	var wm := StandardMaterial3D.new(); wm.albedo_color = wall; wall_mi.material_override = wm
	wall_mi.position = pos + Vector3(0, wh * 0.5, 0); wall_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(wall_mi)
	# atap pelana (prisma segitiga)
	var roof_mi := MeshInstance3D.new()
	var pr := PrismMesh.new(); pr.size = Vector3(size.x * 1.16, wh * 0.6, size.x * 0.95); roof_mi.mesh = pr
	var rm := StandardMaterial3D.new(); rm.albedo_color = roof; roof_mi.material_override = rm
	roof_mi.position = pos + Vector3(0, wh + wh * 0.3, 0); roof_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(roof_mi)
	# pintu menghadap plaza (ke +z bila rumah di utara, dll — sederhana: hadap pusat)
	var door := MeshInstance3D.new()
	var dbm := BoxMesh.new(); dbm.size = Vector3(0.9, wh * 0.55, 0.1); door.mesh = dbm
	var dm := StandardMaterial3D.new(); dm.albedo_color = Color("#2e2118"); door.material_override = dm
	var face := (Vector3(0, 0, 2) - pos).normalized()
	door.position = pos + Vector3(0, wh * 0.28, 0) + face * (size.x * 0.43)
	add_child(door)

func _lantern(pos: Vector3) -> void:
	var post := MeshInstance3D.new()
	var pbm := BoxMesh.new(); pbm.size = Vector3(0.14, 2.0, 0.14); post.mesh = pbm
	var pmat := StandardMaterial3D.new(); pmat.albedo_color = Color("#3a2c20"); post.material_override = pmat
	post.position = pos + Vector3(0, 1.0, 0); add_child(post)
	var bulb := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.22; sm.height = 0.44; bulb.mesh = sm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color("#ffd98a"); bmat.emission_enabled = true
	bmat.emission = Color("#ffcf73"); bmat.emission_energy_multiplier = 1.1
	bulb.material_override = bmat; bulb.position = pos + Vector3(0, 2.05, 0); add_child(bulb)
	var light := OmniLight3D.new()
	light.light_color = Color("#ffc77a"); light.light_energy = 1.5; light.omni_range = 6.5
	light.position = pos + Vector3(0, 2.05, 0); add_child(light)
	_lanterns.append({"light": light, "phase": randf() * TAU})

func _gate(pos: Vector3) -> void:
	# dua pilar + palang atas, lalu label gerbang
	for dx in [-1.7, 1.7]:
		var pil := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = Vector3(0.5, 3.4, 0.5); pil.mesh = bm
		var m := StandardMaterial3D.new(); m.albedo_color = Color("#6f5a40"); pil.material_override = m
		pil.position = pos + Vector3(dx, 1.7, 0); pil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(pil)
	var lintel := MeshInstance3D.new()
	var lbm := BoxMesh.new(); lbm.size = Vector3(4.2, 0.6, 0.6); lintel.mesh = lbm
	var lm := StandardMaterial3D.new(); lm.albedo_color = Color("#5a4730"); lintel.material_override = lm
	lintel.position = pos + Vector3(0, 3.5, 0); add_child(lintel)
	_add_station("depart", "🚪", "Gerbang Hutan", pos, Color("#e7c659"), 2.0)

func _add_station(kind: String, icon: String, name: String, pos: Vector3, color: Color, label_y := 1.5) -> void:
	# cincin penanda di tanah
	var ring := MeshInstance3D.new()
	var cyl := CylinderMesh.new(); cyl.top_radius = 0.95; cyl.bottom_radius = 0.95; cyl.height = 0.05
	ring.mesh = cyl
	var rm := StandardMaterial3D.new()
	rm.albedo_color = color; rm.emission_enabled = true; rm.emission = color; rm.emission_energy_multiplier = 0.8
	ring.material_override = rm; ring.position = pos + Vector3(0, 0.03, 0); add_child(ring)
	# label ikon + nama
	var l := Label3D.new()
	l.text = "%s\n%s" % [icon, name]
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 48; l.outline_size = 14; l.modulate = Color("#f4ecd8")
	l.position = pos + Vector3(0, label_y, 0); add_child(l)
	stations.append({"kind": kind, "name": name, "pos": pos, "label": l, "base_y": label_y})

func _billboard(tex: Texture2D, pos: Vector3, height: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = true
	s.pixel_size = height / float(tex.get_height())
	s.position = pos + Vector3(0, height * 0.5, 0)
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(s)
	return s

func _update_cam() -> void:
	var p := player.position
	cam.position = p + Vector3(1.5, 6.8, 8.0)
	cam.look_at(p + Vector3(0, 0.6, 0), Vector3.UP)

# Ganti sprite seeker sesuai arah jalan (relatif kamera: -z=jauh/belakang, +z=dekat/depan).
func _face_move(d: Vector3) -> void:
	var key := ""
	if absf(d.x) > absf(d.z):
		key = "left" if d.x < 0 else "right"
	else:
		key = "back" if d.z < 0 else "front"
	if key != _facing and _ptex.has(key):
		_facing = key
		player.texture = _ptex[key]

# ---------------- HUD ----------------
func _build_hud() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	hud_msg = Label.new()
	hud_msg.text = "Outpost Verdwall  ·  WASD/panah jalan-jalan  ·  dekati stasiun lalu tekan E/Enter"
	hud_msg.add_theme_font_size_override("font_size", 14)
	hud_msg.add_theme_color_override("font_color", Color("#eef3e9"))
	hud_msg.add_theme_constant_override("outline_size", 5)
	hud_msg.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	hud_msg.position = Vector2(16, 12)
	root.add_child(hud_msg)
	# prompt interaksi (tengah-bawah)
	prompt = Label.new()
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color("#ffe9a8"))
	prompt.add_theme_constant_override("outline_size", 7)
	prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position = Vector2(prompt.position.x, prompt.position.y - 70)
	prompt.visible = false
	root.add_child(prompt)

# ---------------- loop ----------------
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
		np.x = clampf(np.x, -12, 12); np.z = clampf(np.z, -7.5, 8)
		player.position = Vector3(np.x, _player_base_y, np.z)
		_state_player = player.position
		_face_move(dir)
		_update_cam()
	_check_near()
	_animate(delta)

func _animate(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	player.position.y = _player_base_y + sin(t * 3.0) * 0.05
	for s in stations:
		s["label"].position.y = s["base_y"] + sin(t * 2.0 + s["pos"].x) * 0.12
	for lan in _lanterns:
		lan["light"].light_energy = 1.5 + sin(t * 6.0 + lan["phase"]) * 0.3   # kedip lentera

func _check_near() -> void:
	var pp := Vector2(player.position.x, player.position.z)
	var best = null; var bestd := NEAR
	for s in stations:
		var d: float = pp.distance_to(Vector2(s["pos"].x, s["pos"].z))
		if d < bestd:
			bestd = d; best = s
	_near = best
	if _near != null:
		prompt.text = "[ E ]  %s" % _near["name"]
		prompt.visible = true
	else:
		prompt.visible = false

func _input(event: InputEvent) -> void:
	if _near == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			station.emit(_near["kind"])

# ---------------- state ----------------
func get_state() -> Dictionary:
	return {"player": _state_player}

func apply_state(st: Dictionary) -> void:
	if st.is_empty(): return
	if st.has("player") and player != null:
		player.position = st["player"]; _state_player = st["player"]; _update_cam()
