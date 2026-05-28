extends SceneTree
func _init():
	var Level = preload("res://src/world/cave_01/CaveLevel.tscn")
	if Level:
		var l = Level.instantiate()
		root.add_child(l)
		print("CaveLevel loaded successfully! Floor children: ", l.get_node("FloorSegment").get_child_count())
	else:
		print("Failed to load CaveLevel")
	quit()
