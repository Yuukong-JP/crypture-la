extends Node
func _ready() -> void:
	var scn = load("res://scenes/BattlePlay3D.tscn").instantiate()
	scn.enemy_cid = "099"   # Eldergrove (display_scale 1.8) — simulasi raksasa
	scn.enemy_lv = 14
	scn.fresh_party = true
	add_child(scn)
	for i in range(8): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/cap_giant.png")
	print("saved giant; enemy=", scn.battle.enemy["name"])
	get_tree().quit()
