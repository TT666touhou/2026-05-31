extends SceneTree

func _init():
	var scenes = [
		"res://src/entities/player/Player.tscn",
		"res://src/entities/zombie/Zombie.tscn"
	]
	
	for path in scenes:
		var packed = load(path)
		var inst = packed.instantiate()
		
		# check if it already has CoreCollider
		if not inst.has_node("CoreCollider"):
			var col = CollisionShape2D.new()
			col.name = "CoreCollider"
			var shape = CircleShape2D.new()
			shape.radius = 1.0
			col.shape = shape
			inst.add_child(col)
			col.owner = inst
			
			var err = ResourceSaver.save(inst, path)
			print("Saved ", path, ": ", err)
			
	quit()
