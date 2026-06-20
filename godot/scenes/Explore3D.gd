# Explore3D.gd — PROTOTIPE eksplorasi 2.5D ala Octopath (HD-2D vibe).
# Sprite billboard di atas dunia 3D miring + cahaya + bayangan + kabut + bloom.
# Memakai ULANG data zona & sprite Crypture yang sama. Spike/percobaan, bukan final.
extends Node3D

const GRID := 1.7  # jarak antar-petak di dunia 3D

var player: Sprite3D
var cam: Camera3D
var move := Vector3.ZERO

func _ready() -> void:
	# --- Lingkungan & post-processing (rasa HD-2D) ---
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#173026")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#5a7a66")
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color("#2f5142")
	env.fog_density = 0.04
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.15
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.12
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# --- Cahaya matahari sore + bayangan ---
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -38, 0)
	sun.light_energy = 1.15
	sun.light_color = Color("#ffe6c2")
	sun.shadow_enabled = true
	add_child(sun)

	# --- Tanah ---
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 44)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("#3c6b40")
	gm.roughness = 1.0
	ground.material_override = gm
	add_child(ground)

	# --- Pohon (kedalaman/parallax) ---
	var tree_tex: Texture2D = load("res://assets/world/tree.png")
	var spots := [Vector2(-10, -8), Vector2(-7, 4), Vector2(6, -10), Vector2(11, -3),
		Vector2(-13, 2), Vector2(9, 6), Vector2(2, -14), Vector2(-3, 9), Vector2(14, 1)]
	for s in spots:
		_billboard(tree_tex, Vector3(s.x, 0, s.y), 3.2, true)

	# --- Crypture liar (reuse sprite & posisi dari data zona) ---
	var zone: Dictionary = Core.db.world["zone"]
	var w: int = int(zone["size"]["w"])
	var h: int = int(zone["size"]["h"])
	for sp in zone["spawns"]:
		var tex: Texture2D = Core.db.sprite_for(sp["cid"])
		if tex == null:
			continue
		var pos := _grid_to_world(int(sp["x"]), int(sp["y"]), w, h)
		_billboard(tex, pos, 1.7, true)

	# --- Pemain ---
	player = _billboard(load("res://assets/world/seeker.png"), Vector3(0, 0, 0), 2.0, true)

	# --- Kamera miring (mengikuti pemain) ---
	cam = Camera3D.new()
	cam.fov = 50
	cam.rotation_degrees = Vector3(-46, 0, 0)
	add_child(cam)
	_update_cam()

func _grid_to_world(gx: int, gy: int, w: int, h: int) -> Vector3:
	return Vector3((gx - w / 2.0) * GRID, 0, (gy - h / 2.0) * GRID)

func _billboard(tex: Texture2D, pos: Vector3, height: float, shadow: bool) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = true
	s.pixel_size = height / float(tex.get_height())
	s.position = pos + Vector3(0, height * 0.5, 0)
	if shadow:
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(s)
	return s

func _update_cam() -> void:
	cam.position = player.position + Vector3(0, 11, 9)

func _process(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): dir.z -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): dir.z += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1
	if dir != Vector3.ZERO:
		player.position += dir.normalized() * 6.0 * delta
		_update_cam()
