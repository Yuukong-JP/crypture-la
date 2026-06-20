# Shooter.gd — render beberapa layar ke PNG (dipakai via Xvfb untuk screenshot). Bukan bagian game.
extends Node

func _ready() -> void:
	await _sequence()
	get_tree().quit()

func _grab(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("saved ", path)

func _sequence() -> void:
	var main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	await _grab("/tmp/cap_intro.png")
	main.show_hub()
	await get_tree().process_frame
	await _grab("/tmp/cap_hub.png")
	main.show_codex()
	await get_tree().process_frame
	await _grab("/tmp/cap_codex.png")
	main.show_zone()
	await get_tree().process_frame
	await get_tree().process_frame
	await _grab("/tmp/cap_zone.png")
	var spawn = main.zone_view.creatures[0]
	main._on_encounter(spawn)
	await get_tree().process_frame
	await _grab("/tmp/cap_battle.png")
