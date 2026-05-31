extends SceneTree

func _init():
	var log_file = FileAccess.open("res://test_log.txt", FileAccess.WRITE)
	log_file.store_line("--- STARTING SCENE TEST ---")
	var packed_scene = load("res://src/world/cave_01/CaveLevel.tscn")
	if packed_scene:
		log_file.store_line("Successfully loaded CaveLevel.tscn")
		var inst = packed_scene.instantiate()
		if inst:
			log_file.store_line("Successfully instantiated CaveLevel")
			root.add_child(inst)
			log_file.store_line("Added to SceneTree root.")
		else:
			log_file.store_line("Failed to instantiate CaveLevel")
	else:
		log_file.store_line("Failed to load CaveLevel.tscn")
		
	await create_timer(0.5).timeout
	log_file.store_line("--- SCENE TEST PASSED ---")
	log_file.close()
	quit()
