extends Node2D

@export var body_color: Color = Color.WHITE
@export var eye_color: Color = Color.WHITE

# ─── 骨架規格 (Skeletal Dimension Parameters - Scaled Dynamically) ───
@export_group("Skeletal Settings")
@export var base_joint_radius: float = 9.0
@export var base_head_radius: float = 14.0
@export var base_arm_length: float = 18.0
@export var base_head_offset: float = 7.0
@export var base_shoulder_width: float = 18.0

@export_group("Guard & Action Stance")
@export var base_hand_forward: float = 22.0
@export var base_hand_spread: float = 14.0
@export var base_elbow_outward: float = 45.0
@export var base_shoulder_swing: float = 37.5

@export_group("Visual Settings")
@export var base_line_width: float = 4.0
@export var base_head_rect_size: float = 18.0
@export var base_eye_offset_x: float = 2.0
@export var base_eye_offset_y: float = 5.0
@export var base_eye_size: float = 3.0

enum J {
	CENTER, HEAD,
	L_SHOULDER, L_ELBOW, L_HAND,
	R_SHOULDER, R_ELBOW, R_HAND,
	COUNT
}

var character_body: CharacterBody2D
var verlet

var facing_angle: float = 0.0
var walk_blend: float = 0.0

var override_mouse_pos = null # For testing

var scale_factor: float = 1.0

var base_points_count: int = 0
var base_sticks_count: int = 0
var base_motors_count: int = 0
var base_anti_flips_count: int = 0

var current_weapon_rig: Node2D = null

var _hurtbox_node: Area2D = null
var _hurtbox_segments: Array = []
var _head_shape: CollisionShape2D = null

var body_lines = [
	[J.CENTER, J.HEAD],
	[J.HEAD, J.L_SHOULDER],
	[J.HEAD, J.R_SHOULDER],
	[J.L_SHOULDER, J.L_ELBOW],
	[J.L_ELBOW, J.L_HAND],
	[J.R_SHOULDER, J.R_ELBOW],
	[J.R_ELBOW, J.R_HAND]
]

func _ready() -> void:
	# 設定 Light Mask 為 2，使其不接收自身陰影，但仍能被手電筒照亮
	light_mask = 2
	
	character_body = get_parent() as CharacterBody2D
	if character_body:
		scale_factor = character_body.scale.x
		
	var base_pos = character_body.global_position
	
	var VerletPhysicsClass = preload("res://physics/verlet/verlet_physics.gd")
	verlet = VerletPhysicsClass.new()
	
	# 初始化質點
	for i in range(J.COUNT):
		var p_idx = verlet.add_point(base_pos)
		var p = verlet.points[p_idx]
		
		# Point masks will be handled by simulate() global mask
		
		if i in [J.L_HAND, J.R_HAND, J.L_ELBOW, J.R_ELBOW]:
			p.drag = 0.95
			p.radius = base_joint_radius * scale_factor
		elif i == J.HEAD:
			p.drag = 0.90
			p.radius = base_head_radius * scale_factor
		else:
			p.drag = 0.90
			p.radius = base_joint_radius * scale_factor
			
	var s1 = verlet.add_stick(J.L_SHOULDER, J.L_ELBOW, base_arm_length * scale_factor)
	var s2 = verlet.add_stick(J.L_ELBOW, J.L_HAND, base_arm_length * scale_factor)
	var s3 = verlet.add_stick(J.R_SHOULDER, J.R_ELBOW, base_arm_length * scale_factor)
	var s4 = verlet.add_stick(J.R_ELBOW, J.R_HAND, base_arm_length * scale_factor)
	
	# 開啟肢體線段碰撞，讓手在揮動時不會穿模過牆角
	verlet.sticks[s1].collide_terrain = true
	verlet.sticks[s2].collide_terrain = true
	verlet.sticks[s3].collide_terrain = true
	verlet.sticks[s4].collide_terrain = true
	
	verlet.add_motor(J.CENTER, func(): return character_body.global_position, 400.0)
	verlet.add_motor(J.HEAD, func(): return character_body.global_position + Vector2(base_head_offset * scale_factor, 0).rotated(facing_angle), 300.0)
	verlet.add_motor(J.L_SHOULDER, func(): return character_body.global_position + Vector2(0, -base_shoulder_width * scale_factor).rotated(facing_angle), 400.0)
	verlet.add_motor(J.R_SHOULDER, func(): return character_body.global_position + Vector2(0, base_shoulder_width * scale_factor).rotated(facing_angle), 400.0)
	
	base_points_count = verlet.points.size()
	base_sticks_count = verlet.sticks.size()
	base_motors_count = verlet.motors.size()
	base_anti_flips_count = verlet.anti_flips.size()
	
	# 初始化 Hurtbox 動態碰撞箱
	_hurtbox_node = character_body.get_node_or_null("HurtboxComponent")
	if _hurtbox_node:
		# 刪除原有的靜態形狀避免干擾
		for child in _hurtbox_node.get_children():
			if child is CollisionShape2D:
				child.queue_free()
				
		for line_pair in body_lines:
			var cshape = CollisionShape2D.new()
			var cap = CapsuleShape2D.new()
			cap.radius = base_joint_radius * scale_factor
			cshape.shape = cap
			cshape.debug_color = Color(0, 1, 1, 0.42) # Cyan for hurtboxes
			_hurtbox_node.add_child(cshape)
			_hurtbox_segments.append(cshape)
			
		_head_shape = CollisionShape2D.new()
		var circ = CircleShape2D.new()
		circ.radius = base_head_radius * scale_factor
		_head_shape.shape = circ
		_head_shape.debug_color = Color(0, 1, 1, 0.42)
		_hurtbox_node.add_child(_head_shape)

func unequip() -> void:
	if current_weapon_rig:
		current_weapon_rig.queue_free()
		current_weapon_rig = null
	
	# 利用陣列截斷法，將武器加入的物理節點全部清除，恢復成基礎身體
	if verlet:
		verlet.points.resize(base_points_count)
		verlet.sticks.resize(base_sticks_count)
		verlet.motors.resize(base_motors_count)
		verlet.anti_flips.resize(base_anti_flips_count)

func equip(weapon_scene: PackedScene) -> void:
	unequip() # 先解除目前裝備
	if weapon_scene:
		current_weapon_rig = weapon_scene.instantiate() as Node2D
		add_child(current_weapon_rig)
		
		# 初始位置歸零，因為子節點和碰撞箱將以 physics_points 的絕對座標來更新自己的 local_position
		current_weapon_rig.position = Vector2.ZERO
		if current_weapon_rig.has_method("inject_into"):
			current_weapon_rig.inject_into(verlet)
		
		var weapon_controller = current_weapon_rig.get_node_or_null("WeaponController")
		if not weapon_controller:
			weapon_controller = current_weapon_rig
		
		if weapon_controller and weapon_controller.has_method("equip"):
			weapon_controller.equip(verlet, J.L_HAND, J.R_HAND, 1.0)

func _physics_process(delta: float) -> void:
	if not character_body: return
	
	var mouse_pos = get_global_mouse_position()
	if override_mouse_pos != null:
		mouse_pos = override_mouse_pos
		
	var target_angle = (mouse_pos - character_body.global_position).angle()
	facing_angle = lerp_angle(facing_angle, target_angle, delta * 15.0)
	
	if current_weapon_rig:
		var weapon = current_weapon_rig.get_node_or_null("WeaponController")
		if not weapon:
			weapon = current_weapon_rig
			
		if weapon and weapon.has_method("update_owner_status_2d"):
			weapon.update_owner_status_2d(character_body.global_position, facing_angle)
	
	var speed = character_body.velocity.length()
	
	if speed > 10.0:
		walk_blend = move_toward(walk_blend, 1.0, delta * 8.0)
	else:
		walk_blend = move_toward(walk_blend, 0.0, delta * 12.0)
		
	if walk_blend > 0:
		var phase = Time.get_ticks_msec() / 150.0
		var shoulder_swing = sin(phase) * base_shoulder_swing * walk_blend * scale_factor
		verlet.points[J.L_SHOULDER].accumulated_force += Vector2(shoulder_swing, 0).rotated(facing_angle)
		verlet.points[J.R_SHOULDER].accumulated_force += Vector2(-shoulder_swing, 0).rotated(facing_angle)
	
	var l_outward = Vector2(0, -base_elbow_outward * scale_factor).rotated(facing_angle)
	var r_outward = Vector2(0, base_elbow_outward * scale_factor).rotated(facing_angle)
	verlet.points[J.L_ELBOW].accumulated_force += l_outward
	verlet.points[J.R_ELBOW].accumulated_force += r_outward

	var aim_dir = Vector2.RIGHT.rotated(facing_angle)
	var left_target = character_body.global_position + aim_dir * base_hand_forward * scale_factor + aim_dir.rotated(-PI/2) * base_hand_spread * scale_factor
	var right_target = character_body.global_position + aim_dir * base_hand_forward * scale_factor + aim_dir.rotated(PI/2) * base_hand_spread * scale_factor
	verlet.points[J.L_HAND].accumulated_force += (left_target - verlet.points[J.L_HAND].pos) * 375.0 * scale_factor
	verlet.points[J.R_HAND].accumulated_force += (right_target - verlet.points[J.R_HAND].pos) * 375.0 * scale_factor
	
	# 防卡死機制：呼叫共用模組，過遠暫時關閉碰撞
	verlet.enforce_anti_stuck(character_body.global_position)
			
	# 取得 2D 世界的 space_state 進行地形與所有 Hurtbox 碰撞檢測 (mask 281: World=1, PlayerHitbox=8, EnemyHitbox=16, Props=256)
	var space_state = character_body.get_world_2d().direct_space_state
	
	var exclude_rids: Array[RID] = []
	if _hurtbox_node:
		exclude_rids.append(_hurtbox_node.get_rid())
		
	verlet.simulate(delta, space_state, 281, exclude_rids)
	
	# 更新 Hurtbox 動態碰撞箱位置 (轉換為相對於 Player 的 local_position)
	if _hurtbox_node:
		for i in range(body_lines.size()):
			var pair = body_lines[i]
			var pA = verlet.points[pair[0]].pos - character_body.global_position
			var pB = verlet.points[pair[1]].pos - character_body.global_position
			var cshape = _hurtbox_segments[i]
			var cap = cshape.shape as CapsuleShape2D
			var dist = pA.distance_to(pB)
			cap.height = dist + cap.radius * 2.0
			cshape.position = (pA + pB) * 0.5
			cshape.rotation = (pB - pA).angle() + PI/2.0
		
		if _head_shape:
			_head_shape.position = verlet.points[J.HEAD].pos - character_body.global_position
	
	queue_redraw()


func _draw() -> void:
	if not verlet or verlet.points.size() < J.COUNT: return
	
	# 畫手臂連線
	for stick in verlet.sticks:
		if not stick.visible:
			continue
		var pA = (verlet.points[stick.pA].pos - global_position)
		var pB = (verlet.points[stick.pB].pos - global_position)
		draw_line(pA, pB, body_color, base_line_width * scale_factor)
		
	# 畫頭部 (空心方形或圓形)
	var head_pos = (verlet.points[J.HEAD].pos - global_position)
	
	# 可以旋轉畫出的頭部以配合面向
	draw_set_transform(head_pos, facing_angle, Vector2.ONE)
	
	var half_size = base_head_rect_size * 0.5 * scale_factor
	var local_rect = Rect2(Vector2(-half_size, -half_size), Vector2(base_head_rect_size * scale_factor, base_head_rect_size * scale_factor))
	
	# Compute a darker inner color for the face interior (like black for player, dark brown for dummy)
	var inner_color = body_color.darkened(0.8)
	draw_rect(local_rect, inner_color, true) # 內部
	draw_rect(local_rect, body_color, false, base_line_width * scale_factor)
	
	# 畫眼睛
	var ex = base_eye_offset_x * scale_factor
	var ey = base_eye_offset_y * scale_factor
	var es = base_eye_size * scale_factor
	draw_rect(Rect2(Vector2(ex, -ey), Vector2(es, es)), eye_color, true)
	draw_rect(Rect2(Vector2(ex, ey - es), Vector2(es, es)), eye_color, true)
	
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)