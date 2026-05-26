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
	if tip_index != -1 and physics and physics.points.size() > tip_index:
		# 對劍尖施加抗重力，抵銷 980 的下墜力，並額外往上提
		physics.points[tip_index].accumulated_force.y -= 1500.0
		# 對劍尖施加向前的推力，使其保持前傾
		physics.points[tip_index].accumulated_force.x += owner_facing_dir * 800.0
		
	# (未來：ATTACK 狀態會在這裡施加向前的巨大揮砍力)
