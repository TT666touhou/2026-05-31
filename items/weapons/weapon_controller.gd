extends Node
class_name WeaponController

enum State { IDLE, WINDUP, ATTACK, RECOVER }

@export var attack_type: String = "SLASH" # "SLASH" 或 "STAB"
@export var attack_range: float = 150.0

@export var windup_time: float = 0.2
@export var attack_time: float = 0.1
@export var recover_time: float = 0.5

@export var idle_offset: Vector2 = Vector2(30, -30)   # 1點鐘方向
@export var windup_offset: Vector2 = Vector2(-20, -40) # 11點鐘方向
@export var attack_offset: Vector2 = Vector2(40, 40)   # 5點鐘方向

var current_state: State = State.IDLE
var state_timer: float = 0.0

var weapon_rig: VerletRig
var tip_index: int = -1
var base_index: int = -1

# 用於追蹤裝備此武器的實體（例如玩家）的朝向與核心位置
var owner_facing_dir: float = 1.0
var owner_core_pos: Vector2 = Vector2.ZERO

var motor_id: int = -1
var physics: VerletPhysics


# 這個信號當 Area2D 偵測到碰撞時會被觸發
signal hit_target(target_node)

func _ready() -> void:
	# 尋找父節點中的 VerletRig (也就是這把劍)
	weapon_rig = get_parent() as VerletRig
	if not weapon_rig:
		push_warning("WeaponController must be a child of a VerletRig!")
		return
		
	# 我們在稍後的物理處理中會用到
	set_physics_process(true)
	
	# 如果有 Area2D，我們讓它能觸發傷害
	var hitbox = get_node_or_null("../Hitbox") as Area2D
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if current_state == State.ATTACK:
		# 只有在揮砍階段才算有效打擊
		hit_target.emit(body)

func setup_physics(verlet: VerletPhysics, base_idx: int, t_index: int, facing_dir: float) -> void:
	physics = verlet
	base_index = base_idx
	tip_index = t_index
	owner_facing_dir = facing_dir
	# 劍尖現在是純物理擺錘，不需要馬達驅動
	# 馬達會干擾 stick solver，導致手臂被扭曲

func update_owner_status(core_pos: Vector2, facing_dir: float) -> void:
	owner_core_pos = core_pos
	owner_facing_dir = facing_dir

var attack_target_pos: Vector2 = Vector2.ZERO
var attack_is_stab: bool = false

func try_attack(mouse_pos: Vector2) -> bool:
	if current_state == State.IDLE:
		attack_target_pos = mouse_pos
		var dist = weapon_rig.global_position.distance_to(mouse_pos)
		var dir = (mouse_pos - weapon_rig.global_position).normalized()
		
		# 判斷是刺擊還是揮砍
		if dist > 150.0 and abs(dir.y) < 0.5:
			attack_is_stab = true
		else:
			attack_is_stab = false
			
		# 更新面向
		owner_facing_dir = 1.0 if dir.x > 0 else -1.0
			
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
		
	# 基本抗重力 (所有狀態共通，減輕雙臂負擔)
	physics.points[base_index].accumulated_force.y -= 1000.0
	
	match current_state:
		State.IDLE:
			# 閒置：劍尖上揚前傾
			physics.points[tip_index].accumulated_force.y -= 3000.0
			physics.points[tip_index].accumulated_force.x += owner_facing_dir * 1200.0
			
		State.WINDUP:
			# 蓄力：把劍往後上方拉 (抬手準備)
			physics.points[tip_index].accumulated_force.y -= 6000.0
			physics.points[tip_index].accumulated_force.x -= owner_facing_dir * 3000.0
			if state_timer >= windup_time:
				_change_state(State.ATTACK)
				
		State.ATTACK:
			# 爆發攻擊
			var to_target = (attack_target_pos - weapon_rig.global_position).normalized()
			if attack_is_stab:
				# 突刺：給劍尖與劍柄極大的直線推力
				physics.points[tip_index].accumulated_force += to_target * 12000.0
				physics.points[base_index].accumulated_force += to_target * 8000.0
			else:
				# 揮砍：往目標方向，但帶有強烈的下壓與向外甩力
				var slash_dir = to_target + Vector2(0, 1.5) # 強迫向下壓
				physics.points[tip_index].accumulated_force += slash_dir.normalized() * 15000.0
			
			if state_timer >= attack_time:
				_change_state(State.RECOVER)
				
		State.RECOVER:
			# 硬直：停止主動加力，只留微弱抗重力，靠慣性與重力自然下垂
			physics.points[tip_index].accumulated_force.y -= 500.0
			if state_timer >= recover_time:
				_change_state(State.IDLE)
