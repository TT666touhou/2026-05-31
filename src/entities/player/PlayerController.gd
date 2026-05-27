extends CharacterBody2D

class_name PlayerController

@export var move_speed: float = 160.0
@export var dash_speed: float = 500.0

var dash_timer: float = 0.0
var current_dash_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if dash_timer > 0.0:
		dash_timer -= delta
		velocity = current_dash_dir * dash_speed
	else:
		var input_dir = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		)
		
		# 相容原本寫死的 WASD (防止使用者還沒設定 Input Map)
		if input_dir == Vector2.ZERO:
			if Input.is_key_pressed(KEY_D): input_dir.x += 1
			if Input.is_key_pressed(KEY_A): input_dir.x -= 1
			if Input.is_key_pressed(KEY_S): input_dir.y += 1
			if Input.is_key_pressed(KEY_W): input_dir.y -= 1
			
		if input_dir.length_squared() > 1.0:
			input_dir = input_dir.normalized()
			
		if Input.is_action_just_pressed("dash") or Input.is_key_pressed(KEY_SHIFT):
			if input_dir != Vector2.ZERO:
				dash_timer = 0.2
				current_dash_dir = input_dir
				velocity = current_dash_dir * dash_speed
				
		velocity = input_dir * move_speed
		
	move_and_slide()
	
	# 處理攻擊輸入
	if Input.is_action_just_pressed("attack") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var weapon = get_node_or_null("ProceduralDrawer/Sword/WeaponController")
		if weapon and weapon.has_method("try_attack"):
			weapon.try_attack(get_global_mouse_position())
