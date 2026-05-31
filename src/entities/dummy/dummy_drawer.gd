extends Node2D

@export var body_color: Color = Color.WHITE
@export var eye_color: Color = Color.WHITE

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

var target_facing_angle: float = 0.0

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
	character_body = get_parent() as CharacterBody2D
	var base_pos = character_body.global_position
	
	var VerletPhysicsClass = preload("res://src/entities/player/verlet_physics.gd")
	verlet = VerletPhysicsClass.new()
	
	# 初始化質點
	for i in range(J.COUNT):
		var p_idx = verlet.add_point(base_pos)
		var p = verlet.points[p_idx]
		
		if i in [J.L_HAND, J.R_HAND, J.L_ELBOW, J.R_ELBOW]:
			p.drag = 0.95 
		else:
			p.drag = 0.90
			
	var s1 = verlet.add_stick(J.L_SHOULDER, J.L_ELBOW, 10.0)
	var s2 = verlet.add_stick(J.L_ELBOW, J.L_HAND, 10.0)
	var s3 = verlet.add_stick(J.R_SHOULDER, J.R_ELBOW, 10.0)
	var s4 = verlet.add_stick(J.R_ELBOW, J.R_HAND, 10.0)
	
	# 開啟肢體線段碰撞
	verlet.sticks[s1].collide_terrain = true
	verlet.sticks[s2].collide_terrain = true
	verlet.sticks[s3].collide_terrain = true
	verlet.sticks[s4].collide_terrain = true
	
	verlet.add_motor(J.CENTER, func(): return character_body.global_position, 400.0)
	verlet.add_motor(J.HEAD, func(): return character_body.global_position + Vector2(4, 0).rotated(facing_angle), 300.0)
	verlet.add_motor(J.L_SHOULDER, func(): return character_body.global_position + Vector2(0, -10).rotated(facing_angle), 400.0)
	verlet.add_motor(J.R_SHOULDER, func(): return character_body.global_position + Vector2(0, 10).rotated(facing_angle), 400.0)
	
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
			cap.radius = 5.0
			cshape.shape = cap
			cshape.debug_color = Color(0, 1, 1, 0.42) # Cyan for hurtboxes
			_hurtbox_node.add_child(cshape)
			_hurtbox_segments.append(cshape)
			
		_head_shape = CollisionShape2D.new()
		var circ = CircleShape2D.new()
		circ.radius = 8.0
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
		if weapon_controller and weapon_controller.has_method("equip"):
			weapon_controller.equip(verlet, J.L_HAND, J.R_HAND, 1.0)

func _physics_process(delta: float) -> void:
	if not character_body: return
	
	facing_angle = lerp_angle(facing_angle, target_facing_angle, delta * 15.0)
	
	if current_weapon_rig:
		var weapon = current_weapon_rig.get_node_or_null("WeaponController")
		if weapon and weapon.has_method("update_owner_status_2d"):
			weapon.update_owner_status_2d(character_body.global_position, facing_angle)
	
	var speed = character_body.velocity.length()
	
	if speed > 10.0:
		walk_blend = move_toward(walk_blend, 1.0, delta * 8.0)
	else:
		walk_blend = move_toward(walk_blend, 0.0, delta * 12.0)
		
	if walk_blend > 0:
		var phase = Time.get_ticks_msec() / 150.0
		var shoulder_swing = sin(phase) * 75.0 * walk_blend
		verlet.points[J.L_SHOULDER].accumulated_force += Vector2(shoulder_swing, 0).rotated(facing_angle)
		verlet.points[J.R_SHOULDER].accumulated_force += Vector2(-shoulder_swing, 0).rotated(facing_angle)
	
	var l_outward = Vector2(0, -50.0).rotated(facing_angle)
	var r_outward = Vector2(0, 50.0).rotated(facing_angle)
	verlet.points[J.L_ELBOW].accumulated_force += l_outward
	verlet.points[J.R_ELBOW].accumulated_force += r_outward
	
	# Hand constraints to chest (idle stance like player)
	var aim_dir = Vector2.RIGHT.rotated(facing_angle)
	var left_target = character_body.global_position + aim_dir * 12.0 + aim_dir.rotated(-PI/2) * 8.0
	var right_target = character_body.global_position + aim_dir * 12.0 + aim_dir.rotated(PI/2) * 8.0
	verlet.points[J.L_HAND].accumulated_force += (left_target - verlet.points[J.L_HAND].pos) * 750.0
	verlet.points[J.R_HAND].accumulated_force += (right_target - verlet.points[J.R_HAND].pos) * 750.0
	
	if abs(facing_angle - target_facing_angle) > 0.1:
		var l_hand_local = verlet.points[J.L_HAND].pos - character_body.global_position
		print("Dummy Turning. facing_angle: %f, target_facing_angle: %f, l_hand_local: %s, left_target_local: %s" % 
			[facing_angle, target_facing_angle, l_hand_local, left_target - character_body.global_position])
	
	
	# 防卡死機制：呼叫共用模組，過遠暫時關閉碰撞
	verlet.enforce_anti_stuck(character_body.global_position)
	
	# 取得 2D 世界的 space_state 進行地形碰撞檢測 (layer 1)
	var space_state = character_body.get_world_2d().direct_space_state
	verlet.simulate(delta, space_state, 1)
	
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
	
	# 畫身體主幹與手臂連線 (使用 body_lines)
	for pair in body_lines:
		var pA = (verlet.points[pair[0]].pos - global_position)
		var pB = (verlet.points[pair[1]].pos - global_position)
		draw_line(pA, pB, body_color, 2.0)
		
	# 畫頭部 (空心方形或圓形)
	var head_pos = (verlet.points[J.HEAD].pos - global_position)
	
	# 可以旋轉畫出的頭部以配合面向
	draw_set_transform(head_pos, facing_angle, Vector2.ONE)
	var local_rect = Rect2(Vector2(-5, -5), Vector2(10, 10))
	
	# Compute a darker inner color for the face interior (like black for player, dark brown for dummy)
	var inner_color = body_color.darkened(0.8)
	draw_rect(local_rect, inner_color, true) # 內部
	draw_rect(local_rect, body_color, false, 2.0)
	
	# 畫眼睛
	draw_rect(Rect2(Vector2(1, -3), Vector2(2, 2)), eye_color, true)
	draw_rect(Rect2(Vector2(1, 1), Vector2(2, 2)), eye_color, true)
	
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)