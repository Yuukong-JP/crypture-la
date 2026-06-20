extends Node
func _ready() -> void:
	var main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	for i in range(6): await get_tree().process_frame
	main.show_zone()
	for i in range(6): await get_tree().process_frame
	# geser pemain sedikit biar komposisinya enak
	main._explore.player.position += Vector3(2.0, 0, -1.5)
	main._explore._update_cam()
	for i in range(3): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/cap_explore3d_game.png")
	print("saved explore; creatures=", main._explore.creatures.size())
	get_tree().quit()
