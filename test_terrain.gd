extends SceneTree

func _init():
	print("Starting test...")
	var scene = load("res://Main.tscn").instantiate()
	var terrain = scene.get_node("Terrain")
	print("Terrain: ", terrain)
	
	if terrain.has_method("get_used_rect"):
		var rect = terrain.get_used_rect()
		print("Rect: ", rect)
	else:
		print("Terrain DOES NOT have get_used_rect")
	quit()
