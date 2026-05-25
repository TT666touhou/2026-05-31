extends "res://addons/gut/test.gd"

func test_controller_computes_leftward_velocity() -> void:
	var player = preload("res://Player.tscn").instantiate()
	add_child_autofree(player)

	# Press A (move_left — registered in player_controller._ready)
	var key_a := InputEventKey.new()
	key_a.keycode = KEY_A
	key_a.pressed = true
	Input.parse_input_event(key_a)

	# Run 10 physics frames
	for i in range(10):
		player._physics_process(1.0 / 60.0)

	# 控制器必須計算出向左的速度 (velocity.x < -50)
	assert_true(player.velocity.x < -50.0,
		"After 10 frames of KEY_A, velocity.x must be < -50. Got: " + str(player.velocity.x))

	# Release key and let friction stop player
	key_a.pressed = false
	Input.parse_input_event(key_a)

	for _i in range(30):
		player._physics_process(1.0 / 60.0)

	assert_eq(player.velocity.x, 0.0, "Friction must stop player completely")

# EOF
