# ZoneView.gd — eksplorasi zona (GDD Bagian 7): gerak bebas, Crypture terlihat di peta,
# titik lore, pintu keluar. Control agar ikut layout; digambar via _draw, input via _unhandled_input.
extends Control

signal encounter(spawn)
signal reached_exit()
signal lore_collected(text)

const TILE := 44

var db
var zone: Dictionary
var player := {"x": 7, "y": 9}
var creatures: Array = []
var lore: Array = []
var msg := "WASD / panah untuk bergerak. Dekati Crypture untuk encounter. 🚪 = pulang."

func setup(p_db) -> void:
	db = p_db
	focus_mode = Control.FOCUS_ALL
	zone = db.world["zone"]
	player = {"x": 7, "y": 9}
	creatures.clear()
	for s in zone["spawns"]:
		var c: Dictionary = s.duplicate()
		c["alive"] = true
		creatures.append(c)
	lore.clear()
	for l in zone["lore_points"]:
		var lp: Dictionary = l.duplicate()
		lp["used"] = false
		lore.append(lp)
	custom_minimum_size = Vector2(int(zone["size"]["w"]) * TILE, int(zone["size"]["h"]) * TILE)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var dx := 0
	var dy := 0
	match event.keycode:
		KEY_UP, KEY_W: dy = -1
		KEY_DOWN, KEY_S: dy = 1
		KEY_LEFT, KEY_A: dx = -1
		KEY_RIGHT, KEY_D: dx = 1
		_: return
	get_viewport().set_input_as_handled()
	_move(dx, dy)

func _move(dx: int, dy: int) -> void:
	var sz: Dictionary = zone["size"]
	var nx: int = clampi(player["x"] + dx, 0, int(sz["w"]) - 1)
	var ny: int = clampi(player["y"] + dy, 0, int(sz["h"]) - 1)
	player["x"] = nx
	player["y"] = ny
	# perilaku liar sederhana
	for c in creatures:
		if not c["alive"]:
			continue
		if c["behavior"] == "flee" and abs(int(c["x"]) - nx) + abs(int(c["y"]) - ny) <= 3 and randf() < 0.6:
			c["x"] = clampi(int(c["x"]) + (-1 if int(c["x"]) < nx else 1), 0, int(sz["w"]) - 1)
		elif c["behavior"] == "wander" and randf() < 0.3:
			c["x"] = clampi(int(c["x"]) + (-1 if randf() < 0.5 else 1), 0, int(sz["w"]) - 1)

	var ex: Dictionary = zone["exit"]
	if nx == int(ex["x"]) and ny == int(ex["y"]):
		reached_exit.emit()
		return
	for lp in lore:
		if not lp["used"] and int(lp["x"]) == nx and int(lp["y"]) == ny:
			lp["used"] = true
			var g := 0
			# habitat codex
			g = Core.codex.add_from_source(lp["for"], lp["source_type"])
			var sp: Dictionary = db.species[lp["for"]]
			msg = "🌿 %s: %s %s" % [lp["name"], lp["text"], ("Codex %s +%d%%." % [sp["name"], g]) if g > 0 else ""]
			lore_collected.emit(msg)
	for c in creatures:
		if c["alive"] and int(c["x"]) == nx and int(c["y"]) == ny:
			encounter.emit(c)
			return
	queue_redraw()

func mark_defeated(spawn) -> void:
	for c in creatures:
		if c == spawn:
			c["alive"] = false
	queue_redraw()

func _draw() -> void:
	if zone.is_empty():
		return
	var sz: Dictionary = zone["size"]
	var font := ThemeDB.fallback_font
	for y in range(int(sz["h"])):
		for x in range(int(sz["w"])):
			var col := Color("#274a2f") if (x + y) % 2 == 0 else Color("#244328")
			draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), col)
	# pintu keluar
	var ex: Dictionary = zone["exit"]
	draw_string(font, Vector2(int(ex["x"]) * TILE + 8, int(ex["y"]) * TILE + 30), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e7c659"))
	# titik lore
	for lp in lore:
		if lp["used"]:
			continue
		draw_circle(Vector2(int(lp["x"]) * TILE + TILE / 2, int(lp["y"]) * TILE + TILE / 2), 7, Color("#e7c659"))
	# creatures (sprite bila ada, jika tidak lingkaran berhuruf)
	for c in creatures:
		if not c["alive"]:
			continue
		var sp: Dictionary = db.species[c["cid"]]
		var center := Vector2(int(c["x"]) * TILE + TILE / 2, int(c["y"]) * TILE + TILE / 2)
		var tex: Texture2D = db.sprite_for(c["cid"])
		if tex != null:
			var s := float(TILE) + 10.0
			draw_texture_rect(tex, Rect2(center.x - s / 2, center.y - s / 2 - 4, s, s), false)
		else:
			var col := Color(db.colors.get(sp["types"][0], "#999999"))
			draw_circle(center, 15, col)
			draw_string(font, center + Vector2(-6, 6), String(sp["name"]).substr(0, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#11201a"))
	# pemain
	draw_circle(Vector2(player["x"] * TILE + TILE / 2, player["y"] * TILE + TILE / 2), 12, Color("#eef3e9"))
	draw_string(font, Vector2(player["x"] * TILE + TILE / 2 - 6, player["y"] * TILE + TILE / 2 + 6), "S", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#11201a"))
