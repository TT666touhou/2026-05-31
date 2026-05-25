extends SceneTree

func _init():
	print("Testing Camera Placement...")
	var packed = ResourceLoader.load("res://Main.tscn")
	var main = packed.instantiate()
	root.add_child(main)
	
	# Wait for 2 frames to let _ready and layout resolve
	await process_frame
	await process_frame
	
	var cam = main.get_node("TrackingCamera")
	var terrain = main.get_node("Terrain")
	
	print("Camera position: ", cam.global_position)
	print("Camera limit_bottom: ", cam.limit_bottom)
	
	quit()
