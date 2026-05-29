extends Node
class_name WeaponController

enum State { IDLE, WINDUP, ATTACK, RECOVER }

@export var windup_time: float = 0.30
@export var attack_time: float = 0.30
@export var recover_time: float = 0.6

var current_state: State = State.IDLE
var state_timer: float = 0.0
var combo_step: int = 0

var weapon_rig: VerletRig
var tip_index: int = -1
var base_index: int = -1

var owner_facing_angle: float = 0.0
var owner_core_pos: Vector2 = Vector2.ZERO

var motor_id: int = -1
var physics



func _ready() -> void:
	weapon_rig = get_parent() as VerletRig
	if not weapon_rig:
		push_warning("WeaponController must be a child of a VerletRig!")
		return
		
	set_physics_process(true)
	
	var hitbox = get_node_or_null("../Hitbox")
	if hitbox:
		if hitbox.has_method("activate"):
			hitbox.activate() # Keep hitbox permanently active to deal damage on touch
		if hitbox.has_signal("hit_landed"):
			hitbox.hit_landed.connect(_on_hitbox_hit_landed)

func _on_hitbox_hit_landed(_target: Node2D) -> void:
	if tip_index != -1 and physics and physics.points.size() > tip_index:
		# Apply heavy physical drag / resistance to the sword tip
		# By artificially modifying old_pos, we reduce its velocity instantly (Verlet integration)
		var vel = physics.points[tip_index].pos - physics.points[tip_index].old_pos
		# Retain only 10% of the momentum, mimicking thick resistance (cutting through flesh)
		physics.points[tip_index].old_pos = physics.points[tip_index].pos - vel * 0.1

func equip(verlet, l_hand_idx: int, r_hand_idx: int, _facing_dir: float) -> void:
	physics = verlet
	
	var main_hand_pivot = weapon_rig.get_pivot("MainHand")
	if main_hand_pivot:
		base_index = main_hand_pivot.physics_index
		tip_index = weapon_rig.line_point_map[weapon_rig.get_node("Blade")][1]
		
		# 綁定雙手
		physics.add_stick(r_hand_idx, base_index, 0.0, 1.0, false)
		physics.add_stick(l_hand_idx, base_index, 10.0, 1.0, false)
		physics.add_stick(l_hand_idx, tip_index, 18.0, 1.0, false)
		
		# 設定劍尖物理屬性
		physics.points[tip_index].drag = 0.95
		physics.points[tip_index].mass = 1.5

func update_owner_status_2d(core_pos: Vector2, facing_angle: float) -> void:
	owner_core_pos = core_pos
	owner_facing_angle = facing_angle

var locked_aim_dir: Vector2 = Vector2.ZERO

func start_attack(mouse_pos: Vector2) -> void:
	if current_state == State.IDLE or current_state == State.RECOVER:
		locked_aim_dir = (mouse_pos - weapon_rig.global_position).normalized()
		
		if current_state == State.IDLE:
			combo_step = 0
		else:
			combo_step = 1 - combo_step
			
		_change_state(State.WINDUP)

func end_attack(_mouse_pos: Vector2) -> void:
	pass

func _change_state(new_state: State) -> void:
	current_state = new_state
	state_timer = 0.0

func _physics_process(delta: float) -> void:
	state_timer += delta
	if tip_index == -1 or base_index == -1 or not physics or physics.points.size() <= tip_index or physics.points.size() <= base_index:
		return
		
	var mouse_pos = weapon_rig.get_global_mouse_position()
	if weapon_rig.get_parent() and "override_mouse_pos" in weapon_rig.get_parent():
		if weapon_rig.get_parent().override_mouse_pos != null:
			mouse_pos = weapon_rig.get_parent().override_mouse_pos
	
	var _player = weapon_rig.get_parent().get_parent()
	var real_base_global = physics.points[base_index].pos
	var current_aim_dir = (mouse_pos - real_base_global).normalized()
	
	# Update Hitbox dynamically to match the blade physics points exactly
	var hitbox = weapon_rig.get_node_or_null("Hitbox")
	if hitbox:
		var pA = physics.points[base_index].pos
		var pB = physics.points[tip_index].pos
		hitbox.global_position = (pA + pB) * 0.5
		hitbox.global_rotation = (pB - pA).angle() + PI/2.0
		
		
		var shape = hitbox.get_node_or_null("CollisionShape2D")
		if shape:
			shape.debug_color = Color(1, 0.1, 0.1, 0.6) # Very visible Red Hitbox
			
		var pA_old = physics.points[base_index].old_pos
		var pB_old = physics.points[tip_index].old_pos
		var center_current = (pA + pB) * 0.5
		var center_old = (pA_old + pB_old) * 0.5
		var blade_vel = (center_current - center_old)
		if blade_vel.length_squared() > 1.0:
			hitbox.knockback_direction_override = blade_vel.normalized()
	
	match current_state:
		State.IDLE:
			# 閒置：劍尖隨時指向滑鼠，給予拉力 (增強穩定度)
			physics.points[tip_index].accumulated_force += current_aim_dir * 5000.0
			# 給劍柄一個反向抗力，增加穩定度
			physics.points[base_index].accumulated_force -= current_aim_dir * 2000.0
			
		State.WINDUP:
			# 蓄力：將劍高舉並收到側邊準備大範圍揮砍 (連擊時左右互換)
			var normal_dir = Vector2(-locked_aim_dir.y, locked_aim_dir.x)
			var combo_mult = 1.0 if combo_step == 0 else -1.0
			
			var windup_dir = (-locked_aim_dir * 0.5 + normal_dir * 1.5 * combo_mult).normalized()
			physics.points[tip_index].accumulated_force += windup_dir * 6000.0
			physics.points[base_index].accumulated_force -= locked_aim_dir * 2000.0
			
			if state_timer >= windup_time:
				_change_state(State.ATTACK)
				
		State.ATTACK:
			# 順暢的半月形斬擊弧線 (Sweeping Arc)
			var slash_normal = Vector2(-locked_aim_dir.y, locked_aim_dir.x)
			var combo_mult = 1.0 if combo_step == 0 else -1.0
			var progress = state_timer / attack_time
			
			# 從蓄力側完美掃到另一側
			var sweep_normal = lerp(slash_normal * 1.5 * combo_mult, -slash_normal * 1.5 * combo_mult, progress)
			# 揮砍中段給予最強的往前推力 (產生弧線)
			var forward_thrust = sin(progress * PI) * 1.5
			
			var attack_dir = (locked_aim_dir * forward_thrust + sweep_normal).normalized()
			
			physics.points[tip_index].accumulated_force += attack_dir * 19000.0
			physics.points[base_index].accumulated_force += locked_aim_dir * 7500.0
			
			if state_timer >= attack_time:
				_change_state(State.RECOVER)
				
		State.RECOVER:
			# 攻擊結束後的收招，平滑拉回待命姿態
			physics.points[tip_index].accumulated_force += current_aim_dir * 2500.0
			if state_timer >= recover_time:
				_change_state(State.IDLE)
