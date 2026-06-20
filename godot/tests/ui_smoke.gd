# ui_smoke.gd — drive alur UI headless: intro->hub->team->codex->zona->encounter->battle->resolve.
# Catatan: di mode --script, callback _ready tak otomatis jalan, jadi kita paksa init manual.
# Jalankan:  godot --headless --path godot --script res://tests/ui_smoke.gd
extends SceneTree

func _initialize() -> void:
	var core = get_root().get_node("Core")
	core._ready()  # paksa init data/codex/state (autoload _ready belum jalan di mode --script)

	var main = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	main._ready()  # paksa bangun UI

	print("-- navigasi layar --")
	main.show_hub()
	main.show_team()
	main.show_codex()
	main._on_interact(core.db.world["hub"]["interactions"][0])
	main.show_hub()
	main._on_accept("m_codex")

	print("-- masuk zona & gerak --")
	main.show_zone()
	main.zone_view._move(0, -1)
	main.zone_view._move(1, 0)

	print("-- paksa encounter Crypture pertama --")
	var spawn = main.zone_view.creatures[0]
	main._on_encounter(spawn)
	var b = main.battle
	var guard := 0
	while not b.over and guard < 400:
		guard += 1
		if b.pending != null:
			var u = b.pending
			var skill = u["moves"][1] if u["moves"].size() > 1 else null
			if skill != null and int(skill["power"]) > 0:
				main._do_move(skill)
			else:
				main._do_move(u["moves"][0])
	print("    battle selesai: %s dalam %d ronde" % [b.result, b.round_no])
	main._resolve_battle()

	print("-- kembali ke hub & cek state --")
	main.show_hub()
	print("    Rank %d · GP %d · koleksi %d" % [core.state.rank, core.state.gp, core.codex.bonded.size()])

	print("\nUI FLOW OK ✅")
	quit(0)
