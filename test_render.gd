extends SceneTree

var wait_frames = 10

func _init():
	print("--- STARTING RENDER TEST ---")
	var root = get_root()
	var packed_scene = load("res://src/world/cave_01/CaveLevel.tscn")
	if packed_scene:
		var inst = packed_scene.instantiate()
		root.add_child(inst)
		
		# Zoom out camera to see the whole layout
		var player = inst.get_node_or_null("Player")
		if player:
			var cam = player.get_node_or_null("Camera2D")
			if cam:
				cam.zoom = Vector2(0.3, 0.3)
				
		print("Scene instantiated.")
	else:
		printerr("Failed to load scene.")
		quit()
		return

func _process(delta):
	wait_frames -= 1
	if wait_frames <= 0:
		var img = get_root().get_viewport().get_texture().get_image()
		img.save_png("res://test_render_output.png")
		print("Saved screenshot to res://test_render_output.png")
		quit()
