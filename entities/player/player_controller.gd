extends CharacterBody2D

const SPEED = 60.0
const ACCEL = 1000.0
const FRICTION = 1200.0

var capture_timer: int = 0
var capture_interval: int = 2
var frame_count: int = 0
@export var enable_capture: bool = true

func _physics_process(delta: float) -> void:
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	
	if not is_on_floor():
		velocity.y += gravity * delta
	elif Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_SPACE):
		velocity.y = -280.0 # 降低 30% 跳躍高度 (原本 400.0)
		
	# 處理攻擊輸入 (按 J 鍵或滑鼠左鍵)
	if Input.is_key_pressed(KEY_J) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var weapon = get_node_or_null("ProceduralDrawer/Sword/WeaponController")
		if weapon and weapon.has_method("try_attack"):
			weapon.try_attack(get_global_mouse_position())
			
	var direction := Input.get_axis("ui_left", "ui_right")
	if Input.is_key_pressed(KEY_A):
		direction = -1.0
	elif Input.is_key_pressed(KEY_D):
		direction = 1.0
	
	var target_speed = SPEED
	if not is_on_floor():
		target_speed = 105.0 # 降低 30% 空中水平移動上限 (原本 150.0)
		
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * target_speed, ACCEL * delta)
	else:
		# 在空中的水平摩擦力(空氣阻力)可以小一點，讓跳躍更滑順
		var current_friction = FRICTION if is_on_floor() else FRICTION * 0.5
		velocity.x = move_toward(velocity.x, 0, current_friction * delta)
		
	move_and_slide()
	
	# === Debug Frame Capture Logic ===
	if enable_capture and abs(velocity.x) > 10.0 and is_on_floor():
		capture_timer += 1
		if capture_timer >= capture_interval:
			capture_timer = 0
			_capture_frame()

func _capture_frame():
	DirAccess.make_dir_recursive_absolute("res://debug_frames/godot")
		
	var image = get_viewport().get_texture().get_image()
	if image:
		var path = "res://debug_frames/godot/frame_%04d.png" % frame_count
		image.save_png(path)
		print("Captured frame: ", path)
	frame_count += 1
