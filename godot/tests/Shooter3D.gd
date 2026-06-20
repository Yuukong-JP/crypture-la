# Shooter3D.gd — render prototipe Explore3D ke PNG (via Xvfb). Bukan bagian game.
extends Node

func _ready() -> void:
	var scn = load("res://scenes/Explore3D.tscn").instantiate()
	add_child(scn)
	for i in range(8):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/cap_explore3d.png")
	print("saved /tmp/cap_explore3d.png")
	get_tree().quit()
