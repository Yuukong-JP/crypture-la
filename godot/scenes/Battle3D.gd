# Battle3D.gd — PROTOTIPE battle 2.5D (HD-2D) ala Pokémon, commander-model.
# Susunan: Seeker di belakang, 3 Crypture berjajar di depan menghadap lawan di seberang.
# Reuse data & sprite yang SAMA. Spike/percobaan, belum tersambung ke logika battle.
extends Node3D

# Kamera orbit — bisa disetel live (drag mouse = muter, scroll = zoom, P = print angka).
var cam: Camera3D
var cam_target := Vector3(-0.4, 1.0, -1.6)
var cam_yaw := 40.0     # derajat, posisi mengelilingi target (sisi kanan = lawan di kanan)
var cam_pitch := 16.0   # derajat, makin kecil = makin sejajar mata (kurang dari-atas)
var cam_dist := 9.2     # jarak ke target (makin kecil = makin dekat)

func _ready() -> void:
	# --- Lingkungan HD-2D ---
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
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -34, 0)
	sun.light_energy = 1.2
	sun.light_color = Color("#ffe7c4")
	sun.shadow_enabled = true
	add_child(sun)

	# --- Arena: dua platform (sisi pemain & sisi lawan) ---
	_disc(Vector3(0, 0, 3.2), 4.2, Color("#3f6b44"))   # platform pemain
	_disc(Vector3(0, 0, -6.5), 3.6, Color("#4a6552"))  # platform lawan
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("#2c4a35")
	ground.material_override = gm
	ground.position.y = -0.02
	add_child(ground)

	# --- Lawan (seberang, lebih besar) — Mosswhim, front-sprite ---
	var enemy_cid := "015"  # Mosswhim (Rare)
	_unit(Core.db.sprite_for(enemy_cid), Vector3(0, 0, -6.5), 3.0, Core.db.species[enemy_cid]["name"] + " Lv10", Color("#eadfa0"))

	# --- 3 Crypture pemain (jajar depan, BACK-sprite karena tampak punggung) ---
	var party := ["001", "003", "005"]  # Verduck, Pyruff, Ripplet
	var xs := [-2.4, 0.0, 2.4]
	for i in range(3):
		var sp: Dictionary = Core.db.species[party[i]]
		_unit(Core.db.sprite_back_for(party[i]), Vector3(xs[i], 0, 2.6), 1.9, sp["name"], Color("#dff0d6"))

	# --- Seeker di belakang tim ---
	_unit(load("res://assets/world/seeker.png"), Vector3(0, 0, 5.0), 2.1, "Seeker", Color("#cfe0ff"))

	# --- Kamera 3/4 (orbit, bisa disetel live) ---
	cam = Camera3D.new()
	cam.fov = 52
	add_child(cam)
	_apply_cam()

func _apply_cam() -> void:
	var yr := deg_to_rad(cam_yaw)
	var pr := deg_to_rad(cam_pitch)
	var dir := Vector3(sin(yr) * cos(pr), sin(pr), cos(yr) * cos(pr))
	cam.position = cam_target + dir * cam_dist
	cam.look_at(cam_target, Vector3.UP)

func _unhandled_input(e: InputEvent) -> void:
	if cam == null:
		return
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_dist = max(3.0, cam_dist - 0.6); _apply_cam()
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_dist = min(24.0, cam_dist + 0.6); _apply_cam()
	elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT):
		cam_yaw = wrapf(cam_yaw + e.relative.x * 0.3, -180, 180)
		cam_pitch = clampf(cam_pitch - e.relative.y * 0.2, 2.0, 75.0)
		_apply_cam()
	elif e is InputEventKey and e.pressed and e.keycode == KEY_P:
		print("KAMERA -> yaw=%.1f pitch=%.1f dist=%.1f target=%s" % [cam_yaw, cam_pitch, cam_dist, cam_target])

func _disc(pos: Vector3, radius: float, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.18
	mi.mesh = cyl
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	mi.material_override = m
	mi.position = pos
	add_child(mi)

func _unit(tex: Texture2D, pos: Vector3, height: float, name_text: String, name_col: Color) -> void:
	var s := Sprite3D.new()
	s.texture = tex
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = true
	s.pixel_size = height / float(tex.get_height())
	s.position = pos + Vector3(0, height * 0.5, 0)
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(s)
	var lbl := Label3D.new()
	lbl.text = name_text
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 48
	lbl.outline_size = 14
	lbl.modulate = name_col
	lbl.position = pos + Vector3(0, height + 0.5, 0)
	add_child(lbl)
