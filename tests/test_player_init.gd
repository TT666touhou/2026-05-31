extends SceneTree
func _initialize():
    print("=== START INSTANTIATION TEST ===")
    
    var player_scene = load("res://src/entities/player/Player.tscn")
    var player = player_scene.instantiate()
    root.add_child(player)
    
    # Try one frame
    await process_frame
    
    print("=== INSTANTIATION SUCCESS ===")
    quit()
