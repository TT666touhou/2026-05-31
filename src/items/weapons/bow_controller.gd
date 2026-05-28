extends Node
class_name BowController

var weapon_rig: VerletRig
var physics: VerletPhysics

var bow_body_indices: Array[int] = []
var string_indices: Array[int] = []

var main_hand_idx: int = -1
var off_hand_idx: int = -1

var is_pulling: bool = false
var pull_vector: Vector2 = Vector2.ZERO
var charge_time: float = 0.0
var max_charge_time: float = 1.0

func _ready() -> void:
	weapon_rig = get_parent() as VerletRig
	set_physics_process(true)

func equip(verlet, l_hand_idx: int, r_hand_idx: int, _facing_dir: float) -> void:
	physics = verlet
	
	# Extract indices
	var bow_line = weapon_rig.get_node("BowBody")
	var string_line = weapon_rig.get_node("BowString")
	
	bow_body_indices.assign(weapon_rig.line_point_map[bow_line])
	string_indices.assign(weapon_rig.line_point_map[string_line])
	
	# Bind string ends to bow ends
	physics.add_stick(bow_body_indices[0], string_indices[0], 0.0, 1.0, false)
	physics.add_stick(bow_body_indices[-1], string_indices[-1], 0.0, 1.0, false)
	
	# Main hand (right hand) holds the bow center tip
	var grip_idx = bow_body_indices[1]
	physics.add_stick(r_hand_idx, grip_idx, 0.0, 1.0, false)
	main_hand_idx = r_hand_idx
	
	# Off hand (left hand) pulls the string center
	var string_center_idx = string_indices[1]
	physics.add_stick(l_hand_idx, string_center_idx, 0.0, 1.0, false)
	off_hand_idx = l_hand_idx

func update_owner_status_2d(_core_pos: Vector2, _facing_angle: float) -> void:
	pass

func start_attack(_mouse_pos: Vector2) -> void:
	is_pulling = true

func end_attack(_mouse_pos: Vector2) -> void:
	if is_pulling:
		is_pulling = false
		var charge_ratio = charge_time / max_charge_time
		shoot_arrow(charge_ratio)
		charge_time = 0.0

func shoot_arrow(charge_ratio: float) -> void:
	var shoot_scene = preload("res://src/items/weapons/arrow.tscn")
	if shoot_scene:
		var arrow = shoot_scene.instantiate()
		weapon_rig.get_tree().current_scene.add_child(arrow)
		var center_pos = physics.points[bow_body_indices[1]].pos
		arrow.global_position = center_pos
		var string_pos = physics.points[string_indices[1]].pos
		var bow_pos = physics.points[bow_body_indices[1]].pos
		var physical_dir = (bow_pos - string_pos).normalized()
		
		if physical_dir == Vector2.ZERO: physical_dir = Vector2.RIGHT
		
		var final_speed = lerp(800.0, 1600.0, charge_ratio)
		arrow.fire(physical_dir, final_speed)

func _physics_process(_delta: float) -> void:
	if not physics or bow_body_indices.size() == 0: return
	
	var bow_center = bow_body_indices[1]
	var string_center = string_indices[1]
	
	# Safety check in case the weapon was unequipped but queue_free hasn't processed yet
	if physics.points.size() <= bow_center or physics.points.size() <= string_center: return
	
	var mouse_pos = weapon_rig.get_global_mouse_position()
	if weapon_rig.get_parent() and "override_mouse_pos" in weapon_rig.get_parent():
		if weapon_rig.get_parent().override_mouse_pos != null:
			mouse_pos = weapon_rig.get_parent().override_mouse_pos
			
	var base_global = physics.points[bow_center].pos
	var aim_dir = (mouse_pos - base_global).normalized()
	
	var active_aim_dir = aim_dir
	
	if is_pulling:
		charge_time = min(charge_time + _delta, max_charge_time)
		var charge_ratio = charge_time / max_charge_time
		var tension_force = lerp(3000.0, 15000.0, charge_ratio)
		
		# Sway effect: wobbles more the longer it's drawn
		var sway_magnitude = lerp(0.0, 0.25, charge_ratio) # Max sway ~14 degrees
		var sway_angle = sin(Time.get_ticks_msec() * 0.015) * sway_magnitude
		active_aim_dir = aim_dir.rotated(sway_angle)
		
		# Pull string back, push bow forward equally to avoid pulling player backwards
		pull_vector = -active_aim_dir
		physics.points[string_center].accumulated_force += pull_vector * tension_force
		physics.points[bow_center].accumulated_force += active_aim_dir * tension_force
		# Base holding force to keep it in front of the body
		physics.points[bow_center].accumulated_force += active_aim_dir * 3000.0
	else:
		pull_vector = Vector2.ZERO
		charge_time = 0.0
		# Idle holding
		physics.points[bow_center].accumulated_force += active_aim_dir * 3000.0
		
	# -- Enhanced Turning Performance (Apply torque to the tips) --
	if bow_body_indices.size() >= 3:
		var top_tip = bow_body_indices[0]
		var bottom_tip = bow_body_indices[2]
		# Normal vector perpendicular to the aim direction
		var bow_normal = Vector2(-active_aim_dir.y, active_aim_dir.x)
		
		# Force the tips to align perpendicularly to the active aim direction
		# This solves the sluggish turning by directly rotating the bow's arms
		physics.points[top_tip].accumulated_force += -bow_normal * 8000.0
		physics.points[bottom_tip].accumulated_force += bow_normal * 8000.0
