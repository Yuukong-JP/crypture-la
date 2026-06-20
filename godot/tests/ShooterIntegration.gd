# Uji alur penuh: zona -> encounter meluncurkan BattlePlay3D -> mainkan -> selesai -> balik ke zona/hub.
extends Node
func _ready() -> void:
	var main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	for i in range(6): await get_tree().process_frame
	main.show_zone()
	for i in range(4): await get_tree().process_frame
	var c = main._explore.creatures[0]
	var spawn = {"sid": c["sid"], "cid": c["cid"], "level": c["level"]}
	print("encounter: ", spawn["cid"])
	main._on_encounter(spawn)
	for i in range(8): await get_tree().process_frame
	main._battle3d.animate = false  # driver headless: instan
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/cap_int_battle.png")
	print("battle launched? ", main._battle3d != null, " ui_hidden? ", not main._bg.visible)
	# mainkan sampai selesai (naive: skill berdamage, else basic)
	var b = main._battle3d
	var guard := 0
	while not b.battle.over and guard < 80:
		guard += 1
		var u = b.battle.pending
		if u == null: break
		var skill = u["moves"][1] if u["moves"].size() > 1 else null
		if skill != null and int(skill["power"]) > 0: b._ui_move(skill)
		else: b._ui_move(u["moves"][0])
		if guard % 4 == 0: await get_tree().process_frame
	print("battle over? ", b.battle.over, " result=", b.battle.result, " rounds=", b.battle.round_no)
	if not b.battle.over: b._ui_flee()
	await get_tree().process_frame
	b._finish()                      # tekan "Lanjut" -> kembali ke alur Main
	for i in range(4): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/cap_int_after.png")
	print("setelah battle: _battle3d freed? ", main._battle3d == null, " ui_shown? ", main._bg.visible, " GP=", Core.state.gp)
	get_tree().quit()
