# Drive BattlePlay3D headless: ambil screenshot awal, mainkan beberapa giliran, screenshot lagi.
extends Node
func _ready() -> void:
	var scn = load("res://scenes/BattlePlay3D.tscn").instantiate()
	add_child(scn)
	for i in range(8): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/cap_play_start.png")
	print("saved start; enemy hp=", scn.battle.enemy["hp"], "/", scn.battle.enemy["max_hp"])
	# mainkan beberapa giliran (AI: skill bila ada damage, else basic)
	var turns := 0
	while not scn.battle.over and turns < 30:
		turns += 1
		var u = scn.battle.pending
		if u == null: break
		var skill = u["moves"][1] if u["moves"].size() > 1 else null
		if skill != null and int(skill["power"]) > 0: scn._ui_move(skill)
		else: scn._ui_move(u["moves"][0])
		await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/cap_play_mid.png")
	print("saved mid; result=", scn.battle.result, " enemy hp=", scn.battle.enemy["hp"], " rounds=", scn.battle.round_no)
	get_tree().quit()
