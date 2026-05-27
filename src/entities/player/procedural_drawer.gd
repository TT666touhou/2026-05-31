extends Node2D

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

func _ready() -> void:
	character_body = get_parent() as CharacterBody2D
	var base_pos = character_body.global_position
	
	var VerletPhysicsClass = preload("res://physics/verlet/verlet_physics.gd")
	verlet = VerletPhysicsClass.new()
	
	# 初始化質點
	for i in range(J.COUNT):
		var p_idx = verlet.add_point(base_pos)
		var p = verlet.points[p_idx]
		
		# 加入遲滯讓手部有飄動感
		if i in [J.L_HAND, J.R_HAND, J.L_ELBOW, J.R_ELBOW]:
			p.drag = 0.95 
		else:
			p.drag = 0.90
			
	# 建立棍子約束 (手臂)
	verlet.add_stick(J.L_SHOULDER, J.L_ELBOW, 10.0)
	verlet.add_stick(J.L_ELBOW, J.L_HAND, 10.0)
	verlet.add_stick(J.R_SHOULDER, J.R_ELBOW, 10.0)
	verlet.add_stick(J.R_ELBOW, J.R_HAND, 10.0)
	
	# 核心馬達
	verlet.add_motor(J.CENTER, func(): return character_body.global_position, 800.0)
	verlet.add_motor(J.HEAD, func(): return character_body.global_position + Vector2(4, 0).rotated(facing_angle), 600.0)
	verlet.add_motor(J.L_SHOULDER, func(): return character_body.global_position + Vector2(0, -10).rotated(facing_angle), 800.0)
	verlet.add_motor(J.R_SHOULDER, func(): return character_body.global_position + Vector2(0, 10).rotated(facing_angle), 800.0)
	
	# ==== 掛載長劍 ====
	var sword_scene = preload("res://src/items/weapons/sword.tscn")
	if sword_scene:
		var sword_rig = sword_scene.instantiate() as Node2D
		add_child(sword_rig)
		
		# 將劍掛載到右手上
		sword_rig.global_position = verlet.points[J.R_HAND].pos - global_position
		if sword_rig.has_method("inject_into"):
			sword_rig.inject_into(verlet)
		
		# 交由 WeaponController 處理
		var weapon_controller = sword_rig.get_node_or_null("WeaponController")
		if weapon_controller and weapon_controller.has_method("equip"):
			# facing_dir 暫時給 1.0，因為在俯視角武器可能需要改寫
			weapon_controller.equip(verlet, J.L_HAND, J.R_HAND, 1.0)

func _physics_process(delta: float) -> void:
	if not character_body: return
	
	# 透過滑鼠游標決定目標面向
	var mouse_pos = get_global_mouse_position()
	if override_mouse_pos != null:
		mouse_pos = override_mouse_pos
		
	var target_angle = (mouse_pos - character_body.global_position).angle()
	
	# 平滑旋轉
	facing_angle = lerp_angle(facing_angle, target_angle, delta * 15.0)
	
	var weapon = get_node_or_null("Sword/WeaponController")
	if weapon and weapon.has_method("update_owner_status_2d"):
		# 若 WeaponController 支援 2d 角度
		weapon.update_owner_status_2d(character_body.global_position, facing_angle)
	elif weapon and weapon.has_method("update_owner_status"):
		# 相容舊版 API
		weapon.update_owner_status(character_body.global_position, 1.0)
	
	var speed = character_body.velocity.length()
	
	if speed > 10.0:
		walk_blend = move_toward(walk_blend, 1.0, delta * 8.0)
	else:
		walk_blend = move_toward(walk_blend, 0.0, delta * 12.0)
		
	# === 施加生物特定動態力 (Custom Forces) ===
	
	# 移動時讓肩膀稍微前後擺動，模擬步伐感
	if walk_blend > 0:
		var phase = Time.get_ticks_msec() / 150.0
		var shoulder_swing = sin(phase) * 150.0 * walk_blend
		verlet.points[J.L_SHOULDER].accumulated_force += Vector2(shoulder_swing, 0).rotated(facing_angle)
		verlet.points[J.R_SHOULDER].accumulated_force += Vector2(-shoulder_swing, 0).rotated(facing_angle)
	
	# 手肘姿態雕塑：微往外推，形成自然的彎曲
	var l_outward = Vector2(0, -100.0).rotated(facing_angle)
	var r_outward = Vector2(0, 100.0).rotated(facing_angle)
	verlet.points[J.L_ELBOW].accumulated_force += l_outward
	verlet.points[J.R_ELBOW].accumulated_force += r_outward
	
	# 執行泛用物理模擬 (俯視角無重力，所以傳入 Vector2.ZERO)
	# Y 軸限制也取消 (傳入非常大的值)
	verlet.simulate(delta, Vector2.ZERO, 999999.0)
	
	queue_redraw()


func _draw() -> void:
	if not verlet or verlet.points.size() < J.COUNT: return
	
	# 畫手臂連線
	for stick in verlet.sticks:
		if not stick.visible:
			continue
		var pA = (verlet.points[stick.pA].pos - global_position)
		var pB = (verlet.points[stick.pB].pos - global_position)
		draw_line(pA, pB, Color.WHITE, 2.0)
		
	# 畫頭部 (空心方形或圓形)
	var head_pos = (verlet.points[J.HEAD].pos - global_position)
	var rect = Rect2(head_pos - Vector2(5, 5), Vector2(10, 10))
	
	# 可以旋轉畫出的頭部以配合面向
	draw_set_transform(head_pos, facing_angle, Vector2.ONE)
	var local_rect = Rect2(Vector2(-5, -5), Vector2(10, 10))
	draw_rect(local_rect, Color.BLACK, true) # 清空內部 (可選)
	draw_rect(local_rect, Color.WHITE, false, 2.0)
	
	# 畫眼睛
	draw_rect(Rect2(Vector2(1, -3), Vector2(2, 2)), Color.WHITE, true)
	draw_rect(Rect2(Vector2(1, 1), Vector2(2, 2)), Color.WHITE, true)
	
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)