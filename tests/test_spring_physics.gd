extends "res://addons/gut/test.gd"

func test_spring_joints_lag_during_movement() -> void:
	var player = preload("res://Player.tscn").instantiate()
	add_child_autofree(player)
	var drawer := player.get_node("ProceduralDrawer")

	# 模擬角色高速向左移動 20 幀（每幀偏移 8px，繞過 move_and_slide）
	for i in range(20):
		player.global_position += Vector2(-8.0, 0.0)
		drawer._process(1.0 / 60.0)

	# HIPS 質點 (index=0, rest offset x=0) 必須落後於角色
	var hips_target_x: float = player.global_position.x
	var hips_actual_x: float = drawer.positions[0].x
	var lag: float = abs(hips_actual_x - hips_target_x)

	assert_true(lag > 3.0,
		"HIPS must lag >3px behind character (spring active). Lag=" + str(lag))

func test_head_jiggle_after_impulse() -> void:
	var player = preload("res://Player.tscn").instantiate()
	add_child_autofree(player)
	var drawer := player.get_node("ProceduralDrawer")

	# 高速移動 20 幀
	for i in range(20):
		player.global_position += Vector2(-8.0, 0.0)
		drawer._process(1.0 / 60.0)

	# 瞬間停止，只跑彈簧（不移動角色）
	for i in range(5):
		drawer._process(1.0 / 60.0)

	# HEAD_CENTER (index=2, rest offset x=0) 因慣性必須偏移超過 1px
	var head_target_x: float = player.global_position.x
	var head_actual_x: float = drawer.positions[2].x
	var jiggle: float = abs(head_actual_x - head_target_x)

	assert_true(jiggle > 1.0,
		"HEAD must jiggle >1px after brake (empirical Q-spring proof). Jiggle=" + str(jiggle))

# EOF
