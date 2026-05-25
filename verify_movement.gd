extends SceneTree

func _init():
	var packed_main = ResourceLoader.load("res://Main.tscn")
	var main = packed_main.instantiate()
	root.add_child(main)
	
	print("Starting simulation...")
	
	# Wait a bit for initialization
	await create_timer(0.1).timeout
	
	var ragdoll = main.get_node("ActiveRagdoll")
	var torso = ragdoll.get_node("Torso")
	var start_x = torso.global_position.x
	
	print("Torso start x: ", start_x)
	
	# Simulate holding the right key
	var ev = InputEventAction.new()
	ev.action = "ui_right"
	ev.pressed = true
	Input.parse_input_event(ev)
	
	for i in range(120):
		await process_frame
		
	var end_x = torso.global_position.x
	print("Torso end x: ", end_x)
	
	var delta_x = end_x - start_x
	print("Delta X: ", delta_x)
	
	if delta_x > 10.0:
		print("VERIFICATION SUCCESS: Ragdoll walked right by ", delta_x, " pixels.")
	else:
		print("VERIFICATION FAILED: Ragdoll did not move enough.")
		
	quit()
