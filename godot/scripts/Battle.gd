# Battle.gd — GDD Bagian 4: Seeker = commander, Crypture = unit. Turn-based, queue by Speed.
# Port dari src/battle.js. Party 3 di lapangan; HP musuh hidden; aksi Seeker; Apex (Eldergrove).
extends RefCounted

const SCALE := 0.62  # tuning damage global (balance pass nanti)

var data    # GameData
var codex   # Codex
var party: Array
var enemy: Dictionary
var is_apex := false
var log_lines: Array = []
var round_no := 0
var queue: Array = []
var pending = null     # unit pemain yang menunggu perintah, atau null
var over := false
var result := ""       # 'win' | 'lose' | 'bond' | 'flee'
var seeker_cd := 0
var observed := {}
var bonded_instance = null

func _init(p_data, p_codex, p_party: Array, p_enemy: Dictionary) -> void:
	data = p_data
	codex = p_codex
	party = p_party
	enemy = p_enemy
	is_apex = not bool(enemy["species"].get("bondable", true)) and enemy["species"].has("apex_rules")
	var apex_tag := "(APEX — tak bisa di-Bond)" if is_apex else ""
	say("Encounter! %s liar %s muncul." % [enemy["name"], apex_tag])
	start_round()

# ---- util statis ----
static func stage_mult(stage: int) -> float:
	if stage >= 0:
		return (2.0 + stage) / 2.0
	return 2.0 / (2.0 - stage)

static func hp_band(frac: float) -> Dictionary:
	if frac <= 0:
		return {"label": "Tumbang", "cls": "b-out"}
	if frac < 0.18:
		return {"label": "Sekarat", "cls": "b-crit"}
	if frac < 0.4:
		return {"label": "Terluka parah", "cls": "b-low"}
	if frac < 0.7:
		return {"label": "Terluka", "cls": "b-mid"}
	if frac < 0.95:
		return {"label": "Masih kuat", "cls": "b-ok"}
	return {"label": "Segar", "cls": "b-full"}

static func eff_text(m: float) -> String:
	if m == 0:
		return "Tak berpengaruh..."
	if m >= 2:
		return "Serangan telak!"
	if m > 1:
		return "Cukup efektif."
	if m < 1:
		return "Kurang efektif..."
	return ""

func say(t: String) -> void:
	log_lines.append(t)

func all_units() -> Array:
	var a := party.duplicate()
	a.append(enemy)
	return a

func alive_players() -> Array:
	return party.filter(func(u): return u["hp"] > 0)

# ---- damage ----
func calc_damage(attacker: Dictionary, defender: Dictionary, move: Dictionary) -> Dictionary:
	var physical: bool = move["category"] == "Physical"
	var akey := "atk" if physical else "sp_atk"
	var dkey := "def" if physical else "sp_def"
	var a: float = attacker["stats"][akey] * stage_mult(attacker["stat_stages"][akey])
	var d: float = defender["stats"][dkey] * stage_mult(defender["stat_stages"][dkey])
	if attacker["abilities"].has("kindling") and float(attacker["hp"]) / attacker["max_hp"] < 1.0 / 3.0:
		a *= 1.3
	var stab := 1.5 if attacker["types"].has(move["type"]) else 1.0
	var tmult: float = data.type_mult(move["type"], defender["types"])
	var dmg: float = ((2.0 * float(attacker["level"])) / 5.0 + 2.0) * float(move["power"]) * (a / d) / 50.0 + 2.0
	dmg *= stab * tmult * randf_range(0.85, 1.0) * SCALE
	if attacker["enraged"]:
		dmg *= 1.85
	if defender["abilities"].has("bark_skin"):
		dmg *= 0.85
	if defender["abilities"].has("ancient_bark"):
		dmg *= 0.8
	if defender["abilities"].has("sturdy_hide") and physical:
		dmg *= 0.9
	return {"dmg": int(max(1, round(dmg))), "tmult": tmult}

# ---- ronde ----
func start_round() -> void:
	round_no += 1
	if seeker_cd > 0:
		seeker_cd -= 1
	for u in all_units():
		if u["taunt"] > 0:
			u["taunt"] -= 1
	if is_apex and not enemy["enraged"] and float(enemy["hp"]) / enemy["max_hp"] <= float(enemy["species"]["apex_rules"]["phase_at"]):
		enemy["enraged"] = true
		say("🌑 %s memasuki FASE MURKA — serangannya menggila!" % enemy["name"])
	queue = all_units().filter(func(u): return u["hp"] > 0)
	queue.sort_custom(func(a, b):
		return b["stats"]["speed"] * stage_mult(b["stat_stages"]["speed"]) < a["stats"]["speed"] * stage_mult(a["stat_stages"]["speed"]))
	advance()

func advance() -> void:
	while not queue.is_empty():
		var u: Dictionary = queue.pop_front()
		if u["hp"] <= 0:
			continue
		if u == enemy:
			enemy_turn()
			if over:
				return
			continue
		pending = u
		return
	if not over:
		start_round()

# ---- aksi pemain ----
func player_move(move: Dictionary, target_override = null) -> void:
	if pending == null:
		return
	var u: Dictionary = pending
	pending = null
	var target: Dictionary = target_override if target_override != null else enemy
	use_move(u, move, target)
	tick_burn(u)
	after_action()

func use_move(actor: Dictionary, move: Dictionary, target: Dictionary) -> void:
	if actor["status"] == "sleep":
		if randf() < 0.35:
			actor["status"] = ""
			say("%s terbangun!" % actor["name"])
		else:
			say("%s tertidur, tak bisa bergerak." % actor["name"])
			return
	if actor == enemy:
		mark_observed(actor["cid"], move["id"])

	if randf() * 100.0 > float(move["accuracy"]):
		say("%s memakai %s — meleset!" % [actor["name"], move["name"]])
		return

	var eff = move.get("effect", null)
	if eff == null or move["category"] != "Status":
		if int(move["power"]) > 0:
			var r := calc_damage(actor, target, move)
			target["hp"] = max(0, target["hp"] - r["dmg"])
			say(("%s → %s. %s" % [actor["name"], move["name"], eff_text(r["tmult"])]).strip_edges())
			if target["hp"] <= 0:
				say("%s tumbang!" % target["name"])
			if eff != null and eff.get("kind", "") == "aoe":
				for p in party:
					if p["hp"] > 0 and p != target:
						var move2 := move.duplicate()
						move2["power"] = int(round(int(move["power"]) * 0.8))
						var r2 := calc_damage(actor, p, move2)
						p["hp"] = max(0, p["hp"] - r2["dmg"])
						if p["hp"] <= 0:
							say("%s tumbang oleh gelombang!" % p["name"])
				say("Gelombang %s menyapu seluruh tim!" % move["name"])
		if eff != null and eff.get("kind", "") != "aoe":
			apply_effect(actor, target, eff)
	else:
		say("%s memakai %s." % [actor["name"], move["name"]])
		apply_effect(actor, target, eff)

func apply_effect(actor: Dictionary, target: Dictionary, eff) -> void:
	if eff == null:
		return
	var allies := [enemy] if actor["is_wild"] else party
	match eff["kind"]:
		"buff":
			var t: Dictionary = actor if eff["target"] == "self" else target
			t["stat_stages"][eff["stat"]] = int(min(6, t["stat_stages"][eff["stat"]] + int(eff["stages"])))
			say("%s: %s naik." % [t["name"], String(eff["stat"]).to_upper()])
			if eff.has("taunt"):
				actor["taunt"] = int(eff["taunt"]) + 1
				say("%s memancing serangan (taunt)!" % actor["name"])
		"debuff":
			if target["abilities"].has("rooted") and eff["stat"] == "speed":
				say("%s berakar — Speed tak terpengaruh." % target["name"])
			else:
				target["stat_stages"][eff["stat"]] = int(max(-6, target["stat_stages"][eff["stat"]] - int(eff["stages"])))
				say("%s: %s turun." % [target["name"], String(eff["stat"]).to_upper()])
		"status":
			if target["species"].has("apex_rules"):
				say("Kehendak hutan %s kebal terhadap status." % target["name"])
			elif randf() < float(eff.get("chance", 1.0)) and target["status"] == "":
				target["status"] = eff["status"]
				var label := "luka bakar" if eff["status"] == "burn" else String(eff["status"])
				say("%s terkena %s!" % [target["name"], label])
		"heal":
			var pool := []
			if eff["target"] == "self":
				pool = [actor]
			else:
				pool = allies.filter(func(x): return x["hp"] > 0)
				pool.sort_custom(func(a, b): return float(a["hp"]) / a["max_hp"] < float(b["hp"]) / b["max_hp"])
			if not pool.is_empty():
				var t: Dictionary = pool[0]
				var amt := int(round(t["max_hp"] * float(eff["amount"])))
				if actor["abilities"].has("tidecaller"):
					amt = int(round(amt * 1.15))
				t["hp"] = min(t["max_hp"], t["hp"] + amt)
				say("%s pulih %d HP." % [t["name"], amt])
			if eff.has("also"):
				actor["stat_stages"][eff["also"]["stat"]] = int(min(6, actor["stat_stages"][eff["also"]["stat"]] + int(eff["also"]["stages"])))

# ---- aksi Seeker ----
func seeker_action(kind: String, target = null) -> bool:
	if seeker_cd > 0 and kind != "bond":
		return false
	pending = null
	if kind == "potion":
		var t: Dictionary
		if target != null:
			t = target
		else:
			var pool := alive_players()
			pool.sort_custom(func(a, b): return float(a["hp"]) / a["max_hp"] < float(b["hp"]) / b["max_hp"])
			t = pool[0]
		var amt := int(round(t["max_hp"] * 0.45))
		t["hp"] = min(t["max_hp"], t["hp"] + amt)
		say("🧪 Seeker memberi potion: %s pulih %d HP." % [t["name"], amt])
		seeker_cd = 2
	elif kind == "scan":
		say("🔍 Seeker mengamati %s: %s, tipe %s." % [enemy["name"], hp_band(float(enemy["hp"]) / enemy["max_hp"])["label"], ", ".join(enemy["types"])])
		var g: int = codex.add(enemy["cid"], 8)
		if g > 0:
			say("📖 Codex %s: +%d%% (Pindai medan)." % [enemy["name"], g])
		seeker_cd = 1
	elif kind == "bond":
		return attempt_bond()
	after_action()
	return true

func attempt_bond() -> bool:
	if is_apex:
		say("✋ %s adalah Apex — ia tak bisa di-Bond, hanya dipahami lalu dilewati." % enemy["name"])
		after_action()
		return false
	var rate: int = codex.bond_rate(enemy["cid"])
	var roll := randf() * 100.0
	say("🤝 Attempt Bond %s — peluang %d%% (Codex)." % [enemy["name"], rate])
	if roll <= rate:
		over = true
		result = "bond"
		bonded_instance = enemy
		say("✨ BOND berhasil! %s kini berjalan bersamamu." % enemy["name"])
		return true
	say("%s belum cukup percaya... Bond gagal." % enemy["name"])
	after_action()
	return false

# ---- AI musuh ----
func enemy_turn() -> void:
	if enemy["hp"] <= 0:
		return
	var players := alive_players()
	var target: Dictionary
	var taunters := players.filter(func(p): return p["taunt"] > 0)
	if not taunters.is_empty():
		target = taunters[0]
	else:
		var sorted := players.duplicate()
		sorted.sort_custom(func(a, b): return float(a["hp"]) / a["max_hp"] < float(b["hp"]) / b["max_hp"])
		target = sorted[0]
	var skills: Array = enemy["moves"].slice(1)
	var move: Dictionary = enemy["moves"][0]
	if not skills.is_empty():
		if is_apex:
			var crush = null
			for m in skills:
				if m["id"] == "primal_crush":
					crush = m
			if enemy["enraged"] and crush != null and randf() < 0.6:
				move = crush
			elif randf() < 0.85:
				move = skills[randi() % skills.size()]
			else:
				move = enemy["moves"][0]
		else:
			move = skills[0] if randf() < 0.55 else enemy["moves"][0]
	use_move(enemy, move, target)
	tick_burn(enemy)
	check_end()

func after_action() -> void:
	if check_end():
		return
	advance()

func tick_burn(u: Dictionary) -> void:
	if u["status"] == "burn" and u["hp"] > 0:
		var d := int(max(1, round(u["max_hp"] * 0.06)))
		u["hp"] = max(0, u["hp"] - d)
		say("%s tersengat luka bakar (-%d)." % [u["name"], d])

func check_end() -> bool:
	if enemy["hp"] <= 0:
		over = true
		result = "win"
		say("🏆 %s dikalahkan!" % enemy["name"])
		return true
	if alive_players().is_empty():
		over = true
		result = "lose"
		say("💤 Seluruh tim tumbang. Seeker mundur ke Hub.")
		return true
	return false

func mark_observed(cid: String, move_id: String) -> void:
	if not observed.has(cid):
		observed[cid] = {}
	if not observed[cid].has(move_id):
		observed[cid][move_id] = true
		var gained: int = codex.add_from_source(cid, "move_obs")
		if gained > 0:
			say("📖 Codex %s: +%d%% (melihat skill baru)." % [enemy["name"], gained])

func flee() -> void:
	pending = null
	var soft := alive_players().filter(func(p): return p["abilities"].has("soft_steps")).size()
	var chance := 0.5 + 0.1 * soft
	if randf() < chance:
		over = true
		result = "flee"
		say("🏃 Berhasil melarikan diri.")
	else:
		say("Gagal lari!")
		after_action()
