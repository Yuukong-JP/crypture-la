# GameData.gd — Data Spec (GDD Bagian 8): muat data eksternal JSON -> runtime.
# Port dari src/loader.js. Reuse data/*.json yang sama (struktur identik dgn versi web).
extends RefCounted

var raw := {}
var types: Array = []
var chart := {}
var moves := {}
var species := {}
var colors := {}
var world := {}

var _uid := 0
var _sprite_cache := {}

func _init() -> void:
	load_all()

# Texture sprite untuk sebuah Crypture, atau null bila belum ada art.
# Prioritas: sprite_paths.front di data -> konvensi res://assets/crypture/<nama lowercase>.png
func sprite_for(cid: String) -> Texture2D:
	if _sprite_cache.has(cid):
		return _sprite_cache[cid]
	var sp: Dictionary = species[cid]
	var path := ""
	var sps: Variant = sp.get("sprite_paths", {})
	if typeof(sps) == TYPE_DICTIONARY and String(sps.get("front", "")) != "":
		path = String(sps["front"])
	if path == "":
		path = "res://assets/crypture/%s.png" % String(sp["name"]).to_lower()
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	_sprite_cache[cid] = tex
	return tex

# Back-sprite (untuk party di battle, tampak punggung). Fallback ke front bila tak ada.
func sprite_back_for(cid: String) -> Texture2D:
	var key := cid + "_back"
	if _sprite_cache.has(key):
		return _sprite_cache[key]
	var sp: Dictionary = species[cid]
	var path := ""
	var sps: Variant = sp.get("sprite_paths", {})
	if typeof(sps) == TYPE_DICTIONARY and String(sps.get("back", "")) != "":
		path = String(sps["back"])
	if path == "":
		path = "res://assets/crypture/%s_back.png" % String(sp["name"]).to_lower()
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	if tex == null:
		tex = sprite_for(cid)  # fallback ke front
	_sprite_cache[key] = tex
	return tex

func _read_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	assert(f != null, "Tak bisa buka %s" % path)
	var txt := f.get_as_text()
	var data: Variant = JSON.parse_string(txt)
	assert(data != null, "JSON gagal di-parse: %s" % path)
	return data

func load_all() -> void:
	var t: Dictionary = _read_json("res://data/types.json")
	var m: Dictionary = _read_json("res://data/moves.json")
	var c: Dictionary = _read_json("res://data/crypture.json")
	var w: Dictionary = _read_json("res://data/world.json")
	raw = {"types": t, "moves": m, "crypture": c, "world": w}

	types = t["types"]
	colors = t["colors"]
	moves = m["moves"]
	world = w

	# Type chart penuh: default 1.0, lalu timpa dari entri non-1.0
	var all_types: Array = types.duplicate()
	all_types.append("Normal")
	for atk in all_types:
		chart[atk] = {}
		for dfn in all_types:
			chart[atk][dfn] = 1.0
	for atk in t["chart"].keys():
		for dfn in t["chart"][atk].keys():
			chart[atk][dfn] = float(t["chart"][atk][dfn])

	# Index Crypture
	for sp in c["crypture"]:
		species[str(sp["id"])] = sp

	print("[GameData] %d Crypture, %d move, %d tipe dimuat." % [species.size(), moves.size(), types.size()])

func type_mult(move_type: String, defender_types: Array) -> float:
	if move_type == "" or move_type == "Normal":
		return 1.0
	var m := 1.0
	for dt in defender_types:
		if chart.has(move_type):
			m *= float(chart[move_type].get(dt, 1.0))
	return m

func stat_at(sp: Dictionary, key: String, level: int) -> int:
	var base: float = float(sp["base_stats"].get(key, 0))
	var g: float = float(sp.get("growth_curve", {}).get(key, 0))
	return int(round(base + g * (level - 1)))

# Bangun instance Crypture (Dictionary, by-reference seperti objek JS).
func make_instance(cid: String, level: int, is_wild: bool) -> Dictionary:
	var sp: Dictionary = species[cid]
	var mult := 1.0
	if is_wild:
		mult = float(sp.get("wild_multiplier", 1.0))
	var s := {}
	for k in ["hp", "atk", "def", "sp_atk", "sp_def", "speed"]:
		s[k] = int(round(stat_at(sp, k, level) * mult))
	var max_hp := int(round(s["hp"] * 2.4))

	var abil := []
	for a in sp.get("abilities", []):
		if int(a["unlock_level"]) <= level:
			abil.append(a["id"])

	var mv := [moves["basic_strike"], moves[sp["natural_skill"]["move"]]]
	for em in sp.get("extra_moves", []):
		if moves.has(em):
			mv.append(moves[em])

	_uid += 1
	return {
		"uid": _uid,
		"cid": cid,
		"name": sp["name"],
		"species": sp,
		"level": level,
		"is_wild": is_wild,
		"types": sp["types"],
		"role": sp["role"],
		"stats": s,
		"max_hp": max_hp,
		"hp": max_hp,
		"moves": mv,
		"abilities": abil,
		"status": "",
		"stat_stages": {"atk": 0, "def": 0, "sp_atk": 0, "sp_def": 0, "speed": 0},
		"taunt": 0,
		"enraged": false,
	}
