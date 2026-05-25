extends Node2D

@onready var torso: RigidBody2D = $Torso
@onready var head: RigidBody2D = $Head
@onready var l_thigh: RigidBody2D = $L_Thigh
@onready var r_thigh: RigidBody2D = $R_Thigh
@onready var l_foot: RigidBody2D = $L_Foot
@onready var r_foot: RigidBody2D = $R_Foot

var move_speed = 3000.0
var jump_force = 15000.0

func _ready():
	pass

func _physics_process(delta: float) -> void:
	if not torso: return
	
	# 保持身體直立 (Upright PD Control)
	var upright_torque = -torso.rotation * 50000.0 - torso.angular_velocity * 2000.0
	torso.apply_torque(upright_torque)
	
	var dir = 0.0
	if Input.is_action_pressed("ui_right"):
		dir += 1.0
	if Input.is_action_pressed("ui_left"):
		dir -= 1.0
		
	if dir != 0.0:
		if l_foot: l_foot.apply_central_force(Vector2(dir * move_speed, 0))
		if r_foot: r_foot.apply_central_force(Vector2(dir * move_speed, 0))
		torso.apply_central_force(Vector2(dir * move_speed * 0.5, 0))
		
	if Input.is_action_just_pressed("ui_up"):
		if l_foot: l_foot.apply_central_impulse(Vector2(0, -jump_force))
		if r_foot: r_foot.apply_central_impulse(Vector2(0, -jump_force))
		torso.apply_central_impulse(Vector2(0, -jump_force * 2.0))
