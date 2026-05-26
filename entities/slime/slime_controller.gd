extends CharacterBody2D

const SPEED = 60.0
const JUMP_VELOCITY = -250.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var move_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 簡單的史萊姆 AI: 定期向左跳躍
	move_timer -= delta
	if move_timer <= 0.0 and is_on_floor():
		move_timer = randf_range(1.5, 3.0)
		velocity.y = JUMP_VELOCITY
		velocity.x = -SPEED # 向左彈跳
		
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, 400.0 * delta)
		
	move_and_slide()
