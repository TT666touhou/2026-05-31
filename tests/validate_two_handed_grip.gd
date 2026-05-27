extends SceneTree

var player_scene = preload("res://entities/player/player.tscn")
var player: CharacterBody2D
var procedural_drawer: Node2D
var verlet
var J
var passed = true

func _init() -> void:
	print("Starting Dynamic Two-Handed Grip Validation...")
	var root = root
	player = player_scene.instantiate()
	root.add_child(player)
	
	procedural_drawer = player.get_node("ProceduralDrawer")
	J = procedural_drawer.J
	verlet = procedural_drawer.verlet
	
	# Initial stabilization
	for i in range(20):
		await process_frame
	
	print("\n--- TEST: IDLE STANCE ---")
	await validate_frames(10)
	
	print("\n--- TEST: WALKING RIGHT (D) ---")
	player.velocity.x = 100.0 # Simulate speed
	for i in range(60):
		player.global_position.x += player.velocity.x * 0.016 # simulate movement
		await validate_frames(1)
		
	print("\n--- TEST: WALKING LEFT (A) ---")
	player.velocity.x = -100.0
	for i in range(60):
		player.global_position.x += player.velocity.x * 0.016
		await validate_frames(1)
		
	print("\n--- TEST: JUMPING (Space) ---")
	# Simulate jump: high Y velocity, moving forward
	player.velocity.x = 100.0
	player.velocity.y = -400.0
	for i in range(40):
		player.global_position += player.velocity * 0.016
		player.velocity.y += 980.0 * 0.016 # gravity
		await validate_frames(1)

	print("\n--- TEST: ATTACK (Slash) ---")
	var weapon = player.get_node("ProceduralDrawer/Sword/WeaponController")
	# Trigger slash (target close and down)
	weapon.try_attack(player.global_position + Vector2(100, 100))
	
	# Validate during windup, attack, recover
	var total_frames = int((weapon.windup_time + weapon.attack_time + weapon.recover_time) * 60)
	await validate_frames(total_frames, false) # Disable strict sword angle check during attack

	if passed:
		print("\nALL DYNAMIC TESTS PASSED: The grip is stable under movement and attacks!")
	else:
		push_error("\nSOME TESTS FAILED: The pentagon collapsed.")
	
	quit(0 if passed else 1)

func validate_frames(frame_count: int, check_angle: bool = true) -> void:
	for i in range(frame_count):
		await process_frame
		if not passed: return
		
		# Validate conditions
		var spine_x = verlet.points[J.SPINE_TOP].pos.x
		var l_elbow_x = verlet.points[J.L_ELBOW].pos.x
		var r_elbow_x = verlet.points[J.R_ELBOW].pos.x
		var facing_dir = procedural_drawer.facing_dir
		
		# 1. Check elbows are backwards (pentagon shape)
		var l_valid = (l_elbow_x < spine_x) if facing_dir > 0 else (l_elbow_x > spine_x)
		var r_valid = (r_elbow_x < spine_x) if facing_dir > 0 else (r_elbow_x > spine_x)
		
		if not l_valid or not r_valid:
			push_error("FAIL: Elbows collapsed forward! L:" + str(l_elbow_x) + " R:" + str(r_elbow_x) + " Spine:" + str(spine_x))
			passed = false
			return
			
		# 2. Check sword tip and hands
		var sword_rig = procedural_drawer.get_node_or_null("Sword")
		if sword_rig:
			var main_hand_pivot = sword_rig.get_pivot("MainHand")
			var off_hand_pivot = sword_rig.get_pivot("OffHand")
			var blade_tip_idx = sword_rig.line_point_map[sword_rig.get_node("Blade")][1]
			
			var r_hand_pos = verlet.points[J.R_HAND].pos
			var main_hand_pos = verlet.points[main_hand_pivot.physics_index].pos
			
			var l_hand_pos = verlet.points[J.L_HAND].pos
			
			if r_hand_pos.distance_to(main_hand_pos) > 2.0:
				push_error("FAIL: Hands detached from sword during movement!")
				passed = false
				return
				
			# Check blade angle (only when idle/moving, skip during attack as it swings down)
			if check_angle:
				var dir = (verlet.points[blade_tip_idx].pos - main_hand_pos).normalized()
				if dir.y > 0: # Pointing down?
					push_error("FAIL: Blade dropped downwards during movement!")
					passed = false
					return
