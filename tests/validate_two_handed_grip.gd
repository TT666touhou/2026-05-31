extends SceneTree

var player_scene = preload("res://entities/player/player.tscn")
var procedural_drawer: Node2D
var verlet
var J

func _init() -> void:
	print("Starting Two-Handed Grip Physics Validation...")
	var root = root
	var player = player_scene.instantiate()
	root.add_child(player)
	
	procedural_drawer = player.get_node("ProceduralDrawer")
	J = procedural_drawer.J
	
	# 等待幾幀讓物理穩定
	for i in range(30):
		await process_frame
		
	verlet = procedural_drawer.verlet
	
	var passed = true
	
	# 1. Check elbows are backwards
	var spine_x = verlet.points[J.SPINE_TOP].pos.x
	var l_elbow_x = verlet.points[J.L_ELBOW].pos.x
	var r_elbow_x = verlet.points[J.R_ELBOW].pos.x
	
	print("Spine X: ", spine_x)
	print("L Elbow X: ", l_elbow_x)
	print("R Elbow X: ", r_elbow_x)
	
	if l_elbow_x > spine_x or r_elbow_x > spine_x:
		push_error("FAIL: Elbows are not pointing backwards!")
		passed = false
	else:
		print("PASS: Elbows are pointing backwards.")
		
	# 2. Check sword tip is soft and points forward-up
	var sword_rig = procedural_drawer.get_node_or_null("Sword")
	if sword_rig:
		var main_hand_pivot = sword_rig.get_pivot("MainHand")
		var off_hand_pivot = sword_rig.get_pivot("OffHand")
		var blade_tip_idx = sword_rig.line_point_map[sword_rig.get_node("Blade")][1]
		
		# 手部綁定驗證
		var r_hand_pos = verlet.points[J.R_HAND].pos
		var main_hand_pos = verlet.points[main_hand_pivot.physics_index].pos
		var l_hand_pos = verlet.points[J.L_HAND].pos
		var off_hand_pos = verlet.points[off_hand_pivot.physics_index].pos
		
		if r_hand_pos.distance_to(main_hand_pos) > 1.0:
			push_error("FAIL: R_HAND not bound to MainHand")
			passed = false
		if l_hand_pos.distance_to(off_hand_pos) > 1.0:
			push_error("FAIL: L_HAND not bound to OffHand")
			passed = false
			
		var drag = verlet.points[blade_tip_idx].drag
		if drag < 0.95:
			push_error("FAIL: Blade tip drag is too low (" + str(drag) + "), not soft enough")
			passed = false
		else:
			print("PASS: Blade tip drag is high (soft).")
			
		# Check blade angle (should be roughly pointing up/right)
		var dir = (verlet.points[blade_tip_idx].pos - main_hand_pos).normalized()
		print("Blade Direction: ", dir)
		if dir.y > 0: # Pointing down?
			push_error("FAIL: Blade is pointing downwards instead of up!")
			passed = false
		else:
			print("PASS: Blade pointing upwards.")
	else:
		push_error("FAIL: Sword rig not found.")
		passed = false

	if passed:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
	
	quit(0 if passed else 1)
