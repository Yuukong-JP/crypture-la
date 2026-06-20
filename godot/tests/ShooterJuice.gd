# Tangkap satu momen "juice": angka damage melayang + kilatan + lunge (animate=true).
extends Node
func _ready() -> void:
	var scn = load("res://scenes/BattlePlay3D.tscn").instantiate()
	scn.fresh_party = true
	scn.animate = true
	add_child(scn)
	for i in range(10): await get_tree().process_frame
	var u = scn.battle.pending
	var mv = u["moves"][1] if (u["moves"].size() > 1 and int(u["moves"][1]["power"]) > 0) else u["moves"][0]
	scn._ui_move(mv)   # picu animasi (jangan di-await)
	await get_tree().create_timer(0.16).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/cap_juice.png")
	print("saved juice; acted=", u["name"], " move=", mv["name"])
	get_tree().quit()
