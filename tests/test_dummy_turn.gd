extends SceneTree

func _init():
	var Dummy = preload("res://src/entities/dummy/Dummy.tscn")
	var d = Dummy.instantiate()
	root.add_child(d)
	
	d.global_position = Vector2(0, 0)
	
	# Run some ticks to settle
	for i in range(10):
		d.get_node("ProceduralDrawer")._physics_process(0.016)
		
	print("Before hit, target_facing_angle: ", d.get_node("ProceduralDrawer").target_facing_angle)
	d.get_node("ProceduralDrawer").target_facing_angle = PI
	print("After hit, target_facing_angle: ", d.get_node("ProceduralDrawer").target_facing_angle)
	
	# Run ticks to see logs
	for i in range(20):
		d.get_node("ProceduralDrawer")._physics_process(0.016)
		
	print("Test done")
	quit()
