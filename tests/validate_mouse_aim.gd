extends SceneTree

func _init() -> void:
	print("Starting 360-Degree Mouse Aim Validation...")
	var player_scene = preload("res://entities/player/player.tscn")
	var player = player_scene.instantiate()
	# 移除 player_controller 腳本，避免它自己掉落
	player.set_script(null) 
	root.add_child(player)
	
	var procedural_drawer = player.get_node("ProceduralDrawer")
	
	# Initial stabilization
	for i in range(30):
		await process_frame
		
	var sword_rig = procedural_drawer.get_node("Sword")
	var weapon_controller = sword_rig.get_node("WeaponController")
	
	var test_angles = [
		0.0,       # 右
		PI / 4,    # 右下
		PI / 2,    # 下
		3 * PI / 4,# 左下
		PI,        # 左
		-3 * PI / 4,# 左上
		-PI / 2,   # 上
		-PI / 4    # 右上
	]
	
	var passed = true
	
	for angle in test_angles:
		var dist = 300.0
		var mouse_offset = Vector2(cos(angle), sin(angle)) * dist
		var mouse_pos = player.global_position + mouse_offset
		procedural_drawer.override_mouse_pos = mouse_pos
		
		# Give it 60 frames (1 second) to swing the sword to the target
		for i in range(60):
			await process_frame
			
		var tip_index = weapon_controller.tip_index
		var base_index = weapon_controller.base_index
		var physics = weapon_controller.physics
		
		var tip_pos = physics.points[tip_index].pos
		var base_pos = physics.points[base_index].pos
		
		var actual_dir = (tip_pos - base_pos).normalized()
		var expected_dir = (mouse_pos - base_pos).normalized()
		
		var angle_diff_rad = acos(clamp(actual_dir.dot(expected_dir), -1.0, 1.0))
		var angle_diff_deg = rad_to_deg(angle_diff_rad)
		
		print("Angle %.1f deg: Actual vs Expected Diff = %.2f deg" % [rad_to_deg(angle), angle_diff_deg])
		
		if angle_diff_deg > 45.0:
			push_error("ASSERTION FAILED: Sword is not aiming at the mouse! Angle diff is %.2f degrees (Limit 45.0)" % angle_diff_deg)
			print("Base Pos: ", base_pos, " Tip Pos: ", tip_pos, " Mouse Pos: ", mouse_pos)
			passed = false
			break
			
	if passed:
		print("All aiming angles validated successfully.")
		quit(0)
	else:
		quit(1)
