extends Node
func _ready() -> void:
	var scn = load("res://scenes/Battle3D.tscn").instantiate()
	add_child(scn)
	for i in range(8):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/cap_battle3d.png")
	print("saved /tmp/cap_battle3d.png")
	get_tree().quit()
