extends SceneTree

func _init():
    var player_scene = load("res://src/entities/player/Player.tscn")
    var player = player_scene.instantiate()
    var light = player.get_node("VisionLight")
    var file = FileAccess.open("res://test_out.txt", FileAccess.WRITE)
    file.store_string(str(light.range_item_cull_mask))
    file.close()
    quit()
