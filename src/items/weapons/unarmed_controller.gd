extends Node2D

@export_group("Guard Parameters (Scaled Dynamically)")
@export var base_guard_forward: float = 12.0
@export var base_guard_spread: float = 8.0

@export_group("Punch Forces (Scaled Dynamically)")
@export var base_punch_force: float = 15000.0
@export var base_guard_force: float = 1500.0

var physics
var l_hand_idx: int = -1
var r_hand_idx: int = -1

var is_punching: bool = false
var punch_timer: float = 0.0
var punch_duration: float = 0.25
var next_punch_is_left: bool = true

@onready var left_hitbox = $LeftHitbox
@onready var right_hitbox = $RightHitbox

func equip(rig_physics, left_idx: int, right_idx: int, _weight: float) -> void:
	physics = rig_physics
	l_hand_idx = left_idx
	r_hand_idx = right_idx

func update_owner_status_2d(_core_pos: Vector2, _facing_angle: float) -> void:
	pass

func start_attack(_mouse_pos: Vector2) -> void:
	if is_punching: return
	is_punching = true
	punch_timer = punch_duration
	if next_punch_is_left:
		left_hitbox.activate()
	else:
		right_hitbox.activate()

func end_attack(_mouse_pos: Vector2) -> void:
	pass

func _physics_process(delta: float) -> void:
	if not physics or l_hand_idx == -1 or r_hand_idx == -1: return
	
	var rig = get_parent()
	if not rig or not rig.get_parent(): return
	var player = rig.get_parent()
	
	if physics.points.size() > max(l_hand_idx, r_hand_idx):
		left_hitbox.global_position = physics.points[l_hand_idx].pos
		right_hitbox.global_position = physics.points[r_hand_idx].pos
	
	var mouse_pos = get_global_mouse_position()
	if "override_mouse_pos" in rig and rig.override_mouse_pos != null:
		mouse_pos = rig.override_mouse_pos
		
	var aim_dir = (mouse_pos - player.global_position).normalized()
	
	# 動態取得玩家縮放比例
	var scale_factor: float = 1.0
	if "scale_factor" in rig:
		scale_factor = rig.scale_factor
		
	# Calculate idle guard targets using scaled parameters
	var left_target = player.global_position + aim_dir * base_guard_forward * scale_factor + aim_dir.rotated(-PI/2) * base_guard_spread * scale_factor
	var right_target = player.global_position + aim_dir * base_guard_forward * scale_factor + aim_dir.rotated(PI/2) * base_guard_spread * scale_factor
	
	var l_hand = physics.points[l_hand_idx]
	var r_hand = physics.points[r_hand_idx]
	
	if is_punching:
		punch_timer -= delta
		
		# Active hand punches, inactive hand stays in guard
		if next_punch_is_left:
			l_hand.accumulated_force += aim_dir * base_punch_force * scale_factor
			r_hand.accumulated_force += (right_target - r_hand.pos) * base_guard_force * scale_factor
		else:
			r_hand.accumulated_force += aim_dir * base_punch_force * scale_factor
			l_hand.accumulated_force += (left_target - l_hand.pos) * base_guard_force * scale_factor
			
		if punch_timer <= 0.0:
			is_punching = false
			next_punch_is_left = not next_punch_is_left
			left_hitbox.deactivate()
			right_hitbox.deactivate()
	else:
		# Both hands in guard position
		l_hand.accumulated_force += (left_target - l_hand.pos) * base_guard_force * scale_factor
		r_hand.accumulated_force += (right_target - r_hand.pos) * base_guard_force * scale_factor
