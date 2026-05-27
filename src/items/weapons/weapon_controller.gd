extends Node
class_name WeaponController

enum State { IDLE, WINDUP, ATTACK, RECOVER }

@export var windup_time: float = 0.1
@export var attack_time: float = 0.05
@export var recover_time: float = 0.25

var current_state: State = State.IDLE
var state_timer: float = 0.0

var weapon_rig: VerletRig
var tip_index: int = -1
var base_index: int = -1

var owner_facing_angle: float = 0.0
var owner_core_pos: Vector2 = Vector2.ZERO

var motor_id: int = -1
var physics

signal hit_target(target_node)

func _ready() -> void:
	weapon_rig = get_parent() as VerletRig
	if not weapon_rig:
		push_warning("WeaponController must be a child of a VerletRig!")
		return
		
	set_physics_process(true)
	
	var hitbox = get_node_or_null("../Hitbox") as Area2D
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if current_state == State.ATTACK:
		hit_target.emit(body)

func equip(verlet, l_hand_idx: int, r_hand_idx: int, _facing_dir: float) -> void:
	physics = verlet
	
	var main_hand_pivot = weapon_rig.get_pivot("MainHand")
	if main_hand_pivot:
		base_index = main_hand_pivot.physics_index
		tip_index = weapon_rig.line_point_map[weapon_rig.get_node("Blade")][1]
		
		# 綁定雙手
		physics.add_stick(r_hand_idx, base_index, 0.0, 1.0, false)
		physics.add_stick(l_hand_idx, base_index, 10.0, 1.0, false)
		physics.add_stick(l_hand_idx, tip_index, 35.0, 1.0, false)
		
		# 設定劍尖物理屬性
		physics.points[tip_index].drag = 0.95
		physics.points[tip_index].mass = 1.5

func update_owner_status_2d(core_pos: Vector2, facing_angle: float) -> void:
	owner_core_pos = core_pos
	owner_facing_angle = facing_angle

var locked_aim_dir: Vector2 = Vector2.ZERO

func try_attack(mouse_pos: Vector2) -> bool:
	if current_state == State.IDLE or current_state == State.RECOVER:
		locked_aim_dir = (mouse_pos - weapon_rig.global_position).normalized()
		_change_state(State.WINDUP)
		return true
	return false

func _change_state(new_state: State) -> void:
	current_state = new_state
	state_timer = 0.0

func _physics_process(delta: float) -> void:
	state_timer += delta
	if tip_index == -1 or not physics or physics.points.size() <= tip_index:
		return
		
	var mouse_pos = weapon_rig.get_global_mouse_position()
	if weapon_rig.get_parent() and "override_mouse_pos" in weapon_rig.get_parent():
		if weapon_rig.get_parent().override_mouse_pos != null:
			mouse_pos = weapon_rig.get_parent().override_mouse_pos
	
	var real_base_global = weapon_rig.get_parent().global_position + physics.points[base_index].pos
	var current_aim_dir = (mouse_pos - real_base_global).normalized()
	
	match current_state:
		State.IDLE:
			# 閒置：劍尖隨時指向滑鼠，給予拉力
			physics.points[tip_index].accumulated_force += current_aim_dir * 8000.0
			# 給劍柄一個反向抗力，增加穩定度
			physics.points[base_index].accumulated_force -= current_aim_dir * 3000.0
			
		State.WINDUP:
			# 蓄力：順著鎖定的瞄準方向反向拉 (收劍)
			# 為了俯視角的橫劈感，加入一點法線方向的偏移
			var normal_dir = Vector2(-locked_aim_dir.y, locked_aim_dir.x)
			var windup_dir = (-locked_aim_dir + normal_dir * 0.5).normalized()
			physics.points[tip_index].accumulated_force += windup_dir * 5000.0
			physics.points[base_index].accumulated_force -= locked_aim_dir * 1000.0
			
			if state_timer >= windup_time:
				_change_state(State.ATTACK)
				
		State.ATTACK:
			# 爆發攻擊：除了往前，可以加入側向揮砍的力
			var slash_normal = Vector2(-locked_aim_dir.y, locked_aim_dir.x)
			var attack_dir = (locked_aim_dir * 1.5 - slash_normal).normalized()
			
			physics.points[tip_index].accumulated_force += attack_dir * 25000.0
			physics.points[base_index].accumulated_force += locked_aim_dir * 10000.0
			
			if state_timer >= attack_time:
				_change_state(State.RECOVER)
				
		State.RECOVER:
			physics.points[tip_index].accumulated_force += current_aim_dir * 2000.0
			if state_timer >= recover_time:
				_change_state(State.IDLE)
