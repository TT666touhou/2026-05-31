extends SceneTree

var player_scene = preload("res://entities/player/player.tscn")
var procedural_drawer: Node2D
var verlet
var J

func _init() -> void:
	print("Starting Two-Handed Grip Physics Validation with Movement...")
	var root = root
	var player = player_scene.instantiate()
	root.add_child(player)
	
	procedural_drawer = player.get_node("ProceduralDrawer")
	J = procedural_drawer.J
	var character_body = player as CharacterBody2D
	
	print("--- Phase 1: Idle stabilization ---")
	for i in range(30):
		await process_frame
		
	verlet = procedural_drawer.verlet
	var passed = _verify_posture("Idle")
	
	print("--- Phase 2: Running simulation ---")
	# 模擬極高速奔跑，強制觸發 walk_blend = 1.0 以及步態計算
	for i in range(60):
		character_body.velocity.x = 200.0
		# 手動呼叫 _physics_process，因為 CharacterBody2D 的移動會觸發 _physics_process
		# 但我們在 test 裡面可能需要確保它被呼叫
		await process_frame
		
	passed = _verify_posture("Running") and passed
	
	print("--- Phase 3: Post-running stabilization ---")
	# 模擬停止
	for i in range(30):
		character_body.velocity.x = 0.0
		await process_frame
		
	passed = _verify_posture("Post-Running") and passed

	if passed:
		print("ALL TESTS PASSED: Posture is stable across idle and movement.")
	else:
		print("SOME TESTS FAILED: Posture broke.")
	
	quit(0 if passed else 1)

func _verify_posture(phase_name: String) -> bool:
	var passed = true
	var spine_x = verlet.points[J.SPINE_TOP].pos.x
	var l_elbow_x = verlet.points[J.L_ELBOW].pos.x
	var r_elbow_x = verlet.points[J.R_ELBOW].pos.x
	
	if l_elbow_x > spine_x or r_elbow_x > spine_x:
		push_error("[%s] FAIL: Elbows are not pointing backwards!" % phase_name)
		passed = false
	else:
		print("[%s] PASS: Elbows backwards." % phase_name)
		
	var sword_rig = procedural_drawer.get_node_or_null("Sword")
	if sword_rig:
		var main_hand_pivot = sword_rig.get_pivot("MainHand")
		var off_hand_pivot = sword_rig.get_pivot("OffHand")
		var blade_tip_idx = sword_rig.line_point_map[sword_rig.get_node("Blade")][1]
		
		var r_hand_pos = verlet.points[J.R_HAND].pos
		var main_hand_pos = verlet.points[main_hand_pivot.physics_index].pos
		var l_hand_pos = verlet.points[J.L_HAND].pos
		var off_hand_pos = verlet.points[off_hand_pivot.physics_index].pos
		
		if r_hand_pos.distance_to(main_hand_pos) > 1.0:
			push_error("[%s] FAIL: R_HAND detached from MainHand" % phase_name)
			passed = false
		if l_hand_pos.distance_to(off_hand_pos) > 1.0:
			push_error("[%s] FAIL: L_HAND detached from OffHand" % phase_name)
			passed = false
			
		var dir = (verlet.points[blade_tip_idx].pos - main_hand_pos).normalized()
		if dir.y > 0:
			push_error("[%s] FAIL: Blade is pointing downwards instead of up!" % phase_name)
			passed = false
	else:
		push_error("[%s] FAIL: Sword rig not found." % phase_name)
		passed = false
		
	return passed
