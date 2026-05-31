extends CharacterBody2D
class_name PlayerController

@export var move_speed: float = 80.0

@onready var vision_light = get_node_or_null("VisionLight")

func _ready() -> void:
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_S): input_dir.y += 1
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1
	if input_dir.length_squared() > 1.0:
		input_dir = input_dir.normalized()
	velocity = input_dir * move_speed
	move_and_slide()

	if vision_light:
		var mouse_pos := get_global_mouse_position()
		vision_light.rotation = (mouse_pos - global_position).angle()
