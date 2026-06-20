# Codex.gd — GDD Bagian 5 (HOOK UTAMA). Codex 0..100% per Crypture; Bond rate = Codex %.
# Port dari src/codex.js.
extends RefCounted

var data  # GameData
var codex := {}          # cid -> float
var sources_used := {}   # cid -> { detail: true }
var bonded := []         # array instance Dictionary

func _init(game_data) -> void:
	data = game_data

func ensure(cid: String) -> void:
	if not codex.has(cid):
		codex[cid] = 0.0
	if not sources_used.has(cid):
		sources_used[cid] = {}

func get_pct(cid: String) -> int:
	ensure(cid)
	return int(round(codex[cid]))

func bond_rate(cid: String) -> int:
	return int(min(100, round(get_pct(cid))))

func add(cid: String, amt: float) -> int:
	ensure(cid)
	var before: float = codex[cid]
	codex[cid] = min(100.0, before + amt)
	return int(round(codex[cid] - before))

# Tambah dari satu entri info_sources bertipe `type` (sekali pakai per detail).
func add_from_source(cid: String, type: String, detail_key: String = "") -> int:
	ensure(cid)
	var sp: Dictionary = data.species[cid]
	var candidates := []
	for s in sp.get("info_sources", []):
		if s["source_type"] == type:
			candidates.append(s)
	if candidates.is_empty():
		return 0
	var cand: Dictionary = candidates[0]
	if detail_key != "":
		for s in candidates:
			if s["detail"] == detail_key:
				cand = s
				break
	if sources_used[cid].has(cand["detail"]):
		return 0
	sources_used[cid][cand["detail"]] = true
	return add(cid, float(cand["codex_gain"]))

# Lore dari interaksi dunia (NPC/buku) yang menyebut beberapa cid.
func add_lore_from_interaction(interaction: Dictionary) -> Array:
	var out := []
	for cid in interaction.get("gives_lore_for", []):
		ensure(cid)
		var sp: Dictionary = data.species[cid]
		for s in sp.get("info_sources", []):
			if s["source_type"] == "lore" and not sources_used[cid].has(s["detail"]):
				sources_used[cid][s["detail"]] = true
				var g := add(cid, float(s["codex_gain"]))
				if g > 0:
					out.append({"cid": cid, "name": sp["name"], "amt": g, "detail": s["detail"]})
				break
	return out

func is_bonded(cid: String) -> bool:
	for b in bonded:
		if b["cid"] == cid:
			return true
	return false

func add_bonded(instance: Dictionary) -> void:
	bonded.append(instance)
