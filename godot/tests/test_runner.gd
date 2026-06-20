# test_runner.gd — uji logika headless (tanpa scene/UI). Mirror tools/test.js (versi web).
# Jalankan:  godot --headless --path godot --script res://tests/test_runner.gd
extends SceneTree

const GameData := preload("res://scripts/GameData.gd")
const Codex := preload("res://scripts/Codex.gd")
const GameState := preload("res://scripts/GameState.gd")
const BattleClass := preload("res://scripts/Battle.gd")

var fail := 0

func ok(cond: bool, msg: String) -> void:
	print(("  ok  " if cond else " FAIL ") + msg)
	if not cond:
		fail += 1

func _initialize() -> void:
	var db = GameData.new()
	var codex = Codex.new(db)

	print("\n== Langkah 1: data + loader ==")
	ok(db.types.size() == 10, "10 tipe inti dimuat")
	ok(db.type_mult("Ember", ["Nature"]) == 2.0, "Ember vs Nature = 2.0 (dari data)")
	ok(db.type_mult("Nature", ["Ember"]) == 0.5, "Nature vs Ember = 0.5")
	ok(db.type_mult("Normal", ["Nature"]) == 1.0, "Basic/Normal selalu 1.0")
	ok(db.species.size() == 10, "10 Crypture ter-index")
	var cap: Dictionary = db.make_instance("010", 7, true)
	ok(cap["max_hp"] > 0 and cap["moves"].size() == 2, "instance Cappin: max_hp & 2 move")
	var cap_tame: Dictionary = db.make_instance("010", 7, false)
	ok(cap["stats"]["hp"] > cap_tame["stats"]["hp"], "wild_multiplier: liar > versi Bond (LOCKED)")

	print("\n== Langkah 3: Codex -> Bond ==")
	ok(codex.bond_rate("010") == 0, "Codex Cappin mulai 0%")
	codex.add_from_source("010", "encounter")
	codex.add_from_source("010", "move_obs")
	codex.add_lore_from_interaction({"gives_lore_for": ["010"]})
	ok(codex.get_pct("010") > 0, "Codex terisi dari encounter+move_obs+lore")
	for s in db.species["010"]["info_sources"]:
		codex.add_from_source("010", s["source_type"], s["detail"])
	codex.add_lore_from_interaction({"gives_lore_for": ["010"]})
	ok(codex.bond_rate("010") == 100, "Codex penuh -> bond rate 100% (Bond dijamin)")

	print("\n== Langkah 2: Battle (simulasi) ==")
	var wins := 0
	var total_rounds := 0
	for i in range(200):
		var r := _sim(db, codex, ["001", "003", "005"], "011", 7, true)
		if r["result"] == "win":
			wins += 1
		total_rounds += r["rounds"]
	ok(wins >= 140, "Tim 3 menang %d/200 vs wild Common" % wins)
	var avg := float(total_rounds) / 200.0
	ok(avg >= 3 and avg <= 12, "Rata-rata ronde %.1f (target 3-12)" % avg)

	var naive := 0
	var smart := 0
	for i in range(100):
		if _sim_apex(db, codex, false) == "win":
			naive += 1
		if _sim_apex(db, codex, true) == "win":
			smart += 1
	ok(naive < 55, "Apex menghukum main asal-serang: winrate naif %d/100" % naive)
	ok(smart > 70, "Apex bisa ditaklukkan dgn strategi: winrate pintar %d/100" % smart)
	print("    (info) Apex winrate — naif %d%% vs pintar %d%%" % [naive, smart])

	print("\n== Loop: GP -> Rank ==")
	var state = GameState.new(db, Codex.new(db))
	state.init_game()
	ok(state.party.size() == 3 and state.rank == 1, "Start: 3 starter, Rank 1")
	state.add_gp(90, "tes")
	ok(state.rank == 2, "GP 90 -> Rank 2 Trailblazer")
	state.add_gp(150, "tes")
	ok(state.rank == 3 and state.apex_unlocked(), "GP 240 -> Rank 3, Apex terbuka")

	print("\n" + ("SEMUA LULUS ✅" if fail == 0 else "%d GAGAL ❌" % fail))
	quit(1 if fail > 0 else 0)

func _sim(db, codex, pcids: Array, ecid: String, elvl: int, ewild: bool) -> Dictionary:
	var party := []
	for c in pcids:
		party.append(db.make_instance(c, 8, false))
	var enemy: Dictionary = db.make_instance(ecid, elvl, ewild and not db.species[ecid].has("apex_rules"))
	var b = BattleClass.new(db, codex, party, enemy)
	var guard := 0
	while not b.over and guard < 300:
		guard += 1
		if b.pending != null:
			var u: Dictionary = b.pending
			var skill = u["moves"][1] if u["moves"].size() > 1 else null
			var mv = skill if (skill != null and int(skill["power"]) > 0) else u["moves"][0]
			b.player_move(mv)
	return {"result": b.result, "rounds": b.round_no}

func _sim_apex(db, codex, smart: bool) -> String:
	var party := []
	for c in ["001", "003", "005"]:
		party.append(db.make_instance(c, 8, false))
	var enemy: Dictionary = db.make_instance("099", 14, false)
	var b = BattleClass.new(db, codex, party, enemy)
	var guard := 0
	while not b.over and guard < 400:
		guard += 1
		if b.pending == null:
			continue
		var u: Dictionary = b.pending
		var skill = u["moves"][1] if u["moves"].size() > 1 else null
		var crit: bool = b.alive_players().any(func(p): return float(p["hp"]) / p["max_hp"] < 0.3)
		var low: bool = b.alive_players().any(func(p): return float(p["hp"]) / p["max_hp"] < 0.45)
		if smart and crit and b.seeker_cd == 0:
			b.seeker_action("potion")
		elif smart and skill != null and skill.get("effect", null) != null and skill["effect"].get("kind", "") == "heal" and low:
			b.player_move(skill)
		else:
			var mv = skill if (skill != null and int(skill["power"]) > 0) else u["moves"][0]
			b.player_move(mv)
	return b.result
