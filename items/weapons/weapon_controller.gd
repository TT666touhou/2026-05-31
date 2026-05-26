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
	base_index = base_idx
	tip_index = t_index
	owner_facing_dir = facing_dir
	
	# 移除舊的馬達 (如果有的話)
	if motor_id != -1:
		verlet.remove_motor(motor_id)
		
	# 註冊一個新的、由狀態機控制的馬達
	motor_id = verlet.add_motor(tip_index, _get_target_tip_position, 40.0)

func update_owner_status(core_pos: Vector2, facing_dir: float) -> void:
	owner_core_pos = core_pos
	owner_facing_dir = facing_dir

func try_attack() -> bool:
	if current_state == State.IDLE:
		_change_state(State.WINDUP)
		return true
	return false

func _change_state(new_state: State) -> void:
	current_state = new_state
	state_timer = 0.0

func _physics_process(delta: float) -> void:
	state_timer += delta
	
	match current_state:
		State.WINDUP:
			if state_timer >= windup_time:
				_change_state(State.ATTACK)
		State.ATTACK:
			if state_timer >= attack_time:
				_change_state(State.RECOVER)
		State.RECOVER:
			if state_timer >= recover_time:
				_change_state(State.IDLE)
		State.IDLE:
			# 在 Idle 狀態下，如果外面的邏輯想要觸發攻擊 (例如偵測到敵人靠近)，可以呼叫 try_attack()
			pass

# 馬達會不斷呼叫這個函數來決定劍尖應該被拉向哪裡
func _get_target_tip_position() -> Vector2:
	var target_offset = idle_offset
	
	match current_state:
		State.WINDUP:
			target_offset = windup_offset
		State.ATTACK:
			target_offset = attack_offset
		State.RECOVER:
			# 漸變回到 IDLE
			var t = clamp(state_timer / recover_time, 0.0, 1.0)
			target_offset = attack_offset.lerp(idle_offset, t)
	
	# 根據角色的朝向翻轉 X 軸
	target_offset.x *= owner_facing_dir
	
	return owner_core_pos + target_offset
