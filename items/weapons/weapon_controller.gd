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

func equip(verlet: VerletPhysics, l_hand_idx: int, r_hand_idx: int, facing_dir: float) -> void:
	physics = verlet
	owner_facing_dir = facing_dir
	
	var main_hand_pivot = weapon_rig.get_pivot("MainHand")
	if main_hand_pivot:
		base_index = main_hand_pivot.physics_index
		tip_index = weapon_rig.line_point_map[weapon_rig.get_node("Blade")][1]
		
		# 綁定雙手
		physics.add_stick(r_hand_idx, base_index, 0.0, 1.0, false)
		physics.add_stick(l_hand_idx, base_index, 10.0, 1.0, false)
		physics.add_stick(l_hand_idx, tip_index, 35.0, 1.0, false)
		
		# 設定劍尖物理屬性
		physics.points[tip_index].drag = 0.98
		physics.points[tip_index].mass = 1.5

func update_owner_status(core_pos: Vector2, facing_dir: float) -> void:
	owner_core_pos = core_pos
	owner_facing_dir = facing_dir

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
		
	# 計算即時的滑鼠瞄準方向 (用於 IDLE 和 RECOVER)
	var mouse_pos = get_viewport().get_mouse_position() # 如果有 Camera2D 的話，可能要用 get_global_mouse_position()
	# 註：因為在 Node 裡面，最好用 get_global_mouse_position()
	# 但是 WeaponController 不是 CanvasItem，我們可以用 weapon_rig.get_global_mouse_position()
	var current_aim_dir = (weapon_rig.get_global_mouse_position() - weapon_rig.global_position).normalized()
	
	# 基本抗重力 (減輕雙臂負擔)
	physics.points[base_index].accumulated_force.y -= 1000.0
	
	match current_state:
		State.IDLE:
			# 閒置：劍尖隨時指向滑鼠
			physics.points[tip_index].accumulated_force += current_aim_dir * 3000.0
			# 給劍柄一個反向的抗力，避免整個身體被劍拖著走
			physics.points[base_index].accumulated_force -= current_aim_dir * 500.0
			
		State.WINDUP:
			# 蓄力：順著鎖定的瞄準方向反向拉 (收劍)
			physics.points[tip_index].accumulated_force -= locked_aim_dir * 4000.0
			physics.points[base_index].accumulated_force -= locked_aim_dir * 1000.0
			if state_timer >= windup_time:
				_change_state(State.ATTACK)
				
		State.ATTACK:
			# 爆發攻擊：朝著鎖定的瞄準方向進行強大的直線突刺
			physics.points[tip_index].accumulated_force += locked_aim_dir * 18000.0
			physics.points[base_index].accumulated_force += locked_aim_dir * 12000.0
			
			if state_timer >= attack_time:
				_change_state(State.RECOVER)
				
		State.RECOVER:
			# 硬直：稍微恢復追蹤滑鼠，但力度較弱
			physics.points[tip_index].accumulated_force += current_aim_dir * 1000.0
			if state_timer >= recover_time:
				_change_state(State.IDLE)
