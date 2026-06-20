# GameState.gd — GDD Bagian 2/3/6: state game, core loop, Rank/GP, progres misi.
# Port dari src/world.js.
extends RefCounted

var data    # GameData
var codex   # Codex
var W: Dictionary

var gp := 0
var rank := 1
var party: Array = []
var flags := {"battles_won": 0, "bond_count": 0}
var missions := {}   # id -> 'available' | 'active' | 'done' | 'locked'
var log_lines: Array = []

func _init(p_data, p_codex) -> void:
	data = p_data
	codex = p_codex
	W = data.world

func rank_info(r: int) -> Dictionary:
	for x in W["ranks"]:
		if int(x["rank"]) == r:
			return x
	return {}

func next_rank() -> Variant:
	for x in W["ranks"]:
		if int(x["rank"]) == rank + 1:
			return x
	return null

func init_game() -> void:
	party = [
		data.make_instance("001", 8, false),
		data.make_instance("003", 8, false),
		data.make_instance("005", 8, false),
	]
	for p in party:
		codex.add(p["cid"], 100)
		codex.add_bonded(p)
	for m in W["missions"]:
		missions[m["id"]] = "available" if int(m["rank_req"]) <= rank else "locked"
	missions["m_intro"] = "active"

func add_gp(amount: int, why: String) -> void:
	gp += amount
	log_lines.append("+%d GP — %s" % [amount, why])
	check_rank_up()

func check_rank_up():
	var leveled: Variant = null
	var nr: Variant = next_rank()
	while nr != null and not bool(nr.get("placeholder", false)) and gp >= int(nr["gp_required"]):
		rank = int(nr["rank"])
		leveled = nr
		for m in W["missions"]:
			if missions[m["id"]] == "locked" and int(m["rank_req"]) <= rank:
				missions[m["id"]] = "available"
		nr = next_rank()
	return leveled

func on_battle_result(battle) -> Array:
	var events := []
	if battle.result == "win" or battle.result == "bond":
		flags["battles_won"] += 1
	if battle.result == "bond":
		flags["bond_count"] += 1
		var inst: Dictionary = battle.bonded_instance
		var tamed: Dictionary = data.make_instance(inst["cid"], inst["level"], false)
		codex.add_bonded(tamed)
		events.append("%s bergabung ke koleksi." % inst["name"])
		if codex.get_pct(inst["cid"]) >= 100:
			add_gp(int(W["gp_rewards"]["codex_complete"]), "Codex %s 100%%" % inst["name"])
	for m in W["missions"]:
		if missions[m["id"]] != "active":
			continue
		var g: Dictionary = m["goal"]
		var done := false
		match g["kind"]:
			"win_any_battle":
				done = battle.result == "win" or battle.result == "bond"
			"bond":
				done = battle.result == "bond" and battle.bonded_instance["cid"] == g["cid"]
			"bond_count":
				done = flags["bond_count"] >= int(g["count"])
			"defeat_apex":
				done = battle.result == "win" and battle.enemy["cid"] == g["cid"]
		if done:
			missions[m["id"]] = "done"
			add_gp(int(m["gp"]), "Misi: %s" % m["name"])
			events.append("✅ Misi selesai: %s (+%d GP)" % [m["name"], int(m["gp"])])
	return events

func accept_mission(id: String) -> void:
	if missions.get(id, "") == "available":
		missions[id] = "active"

func missions_by_state(state: String) -> Array:
	var out := []
	for m in W["missions"]:
		if missions.get(m["id"], "") == state:
			out.append(m)
	return out

func active_missions() -> Array:
	return missions_by_state("active")

func available_missions() -> Array:
	return missions_by_state("available")

func apex_unlocked() -> bool:
	return rank >= 3
