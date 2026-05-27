extends Node2D

enum J {
	HIPS, SPINE_TOP, HEAD_CENTER,
	L_ELBOW, L_HAND,
	R_ELBOW, R_HAND,
	L_KNEE, L_FOOT,
	R_KNEE, R_FOOT,
	COUNT
}

var character_body: CharacterBody2D
var verlet

const STRIDE_LENGTH = 28.0
const STEP_HEIGHT = 6.0

var facing_dir: float = 1.0
var target_facing_dir: float = 1.0
var walk_blend: float = 0.0

var l_phase: float = 0.0
var r_phase: float = 0.0

var override_mouse_pos = null # For testing

func _ready() -> void:
	character_body = get_parent() as CharacterBody2D
	var base_pos = character_body.global_position
	
	var VerletPhysicsClass = preload("res://physics/verlet/verlet_physics.gd")
	verlet = VerletPhysicsClass.new()
	
	# 初始化質點 (大致設定初始位置)
	for i in range(J.COUNT):
		var offset = Vector2.ZERO
		match i:
			J.HIPS: offset = Vector2(0, -21)
			J.SPINE_TOP: offset = Vector2(0, -29)
			J.HEAD_CENTER: offset = Vector2(0, -35)
			J.L_ELBOW: offset = Vector2(-10, -19)
			J.L_HAND: offset = Vector2(-10, -9)
			J.R_ELBOW: offset = Vector2(10, -19)
			J.R_HAND: offset = Vector2(10, -9)
			J.L_KNEE: offset = Vector2(-5, -10.5)
			J.L_FOOT: offset = Vector2(-10, 0)
			J.R_KNEE: offset = Vector2(5, -10.5)
			J.R_FOOT: offset = Vector2(10, 0)
			
		var p_idx = verlet.add_point(base_pos + offset)
		var p = verlet.points[p_idx]
		
		# 設定個別阻尼與特例
		if i == J.HEAD_CENTER or i == J.SPINE_TOP:
			p.drag = 0.98 # 極大的慣性
			
		if i == J.L_FOOT or i == J.R_FOOT:
			p.friction = 0.99 # 極端地板摩擦力
			
	# 建立棍子約束 (保持 1:2.67 的魔性細長四肢比例)
	verlet.add_stick(J.HIPS, J.SPINE_TOP, 8.0)
	verlet.add_stick(J.SPINE_TOP, J.HEAD_CENTER, 6.0)
	
	verlet.add_stick(J.SPINE_TOP, J.L_ELBOW, 10.0)
	verlet.add_stick(J.L_ELBOW, J.L_HAND, 10.0)
	verlet.add_stick(J.SPINE_TOP, J.R_ELBOW, 10.0)
	verlet.add_stick(J.R_ELBOW, J.R_HAND, 10.0)
	
	verlet.add_stick(J.HIPS, J.L_KNEE, 10.5)
	verlet.add_stick(J.L_KNEE, J.L_FOOT, 10.5)
	verlet.add_stick(J.HIPS, J.R_KNEE, 10.5)
	verlet.add_stick(J.R_KNEE, J.R_FOOT, 10.5)
	
	# 加入核心彈簧馬達 (Motor IK)
	verlet.add_motor(J.HIPS, func(): return character_body.global_position + Vector2(0, -21), 600.0)
	
	# 脊椎只限制 Y 軸，讓 X 軸可以自然搖擺
	verlet.add_motor(J.SPINE_TOP, func(): return character_body.global_position + Vector2(0, -29), 600.0, Vector2(0, 1))
	verlet.add_motor(J.HEAD_CENTER, func(): return character_body.global_position + Vector2(0, -35), 400.0, Vector2(0, 1))
	
	# 腳部彈射馬達
	verlet.add_motor(J.L_FOOT, func(): 
		return character_body.global_position + Vector2(-10, 0) + _get_foot_offset(l_phase, STRIDE_LENGTH) * walk_blend
	, 800.0)
	verlet.add_motor(J.R_FOOT, func(): 
		return character_body.global_position + Vector2(10, 0) + _get_foot_offset(r_phase, STRIDE_LENGTH) * walk_blend
	, 800.0)
	
	# ==== 掛載長劍 ====
	var sword_scene = preload("res://items/weapons/sword.tscn")
	var sword_rig = sword_scene.instantiate() as VerletRig
	add_child(sword_rig)
	
	# 將劍掛載到右手上
	sword_rig.global_position = verlet.points[J.R_HAND].pos - global_position
	sword_rig.inject_into(verlet)
	
	# 將實體與武器的綁定邏輯交由 WeaponController 處理
	var weapon_controller = sword_rig.get_node_or_null("WeaponController")
	if weapon_controller and weapon_controller.has_method("equip"):
		weapon_controller.equip(verlet, J.L_HAND, J.R_HAND, facing_dir)

func _get_foot_offset(phase: float, stride: float) -> Vector2:
	var amplitude = stride / 2.0
	if phase < 0.5: # 腳向後滑 (接地)
		var t = phase * 2.0
		var x = lerp(amplitude, -amplitude, t)
		return Vector2(x, 0.0)
	else: # 腳向前抬 (騰空)
		var t = (phase - 0.5) * 2.0
		var x = lerp(-amplitude, amplitude, t)
		var y = -sin(t * PI) * STEP_HEIGHT
		return Vector2(x, y)

func _physics_process(delta: float) -> void:
	if not character_body: return
	
	# 透過滑鼠游標決定目標面向
	var mouse_pos = get_global_mouse_position()
	if override_mouse_pos != null:
		mouse_pos = override_mouse_pos
		
	if mouse_pos.x > character_body.global_position.x:
		target_facing_dir = 1.0
	else:
		target_facing_dir = -1.0
		
	# 平滑線性過渡 (轉身動畫時間約 0.25 秒)
	facing_dir = move_toward(facing_dir, target_facing_dir, delta * 8.0)
	
	var weapon = get_node_or_null("Sword/WeaponController")
	if weapon and weapon.has_method("update_owner_status"):
		weapon.update_owner_status(character_body.global_position, facing_dir)
	
	var speed = character_body.velocity.x
	
	if abs(speed) > 10.0:
		walk_blend = move_toward(walk_blend, 1.0, delta * 8.0)
	else:
		walk_blend = move_toward(walk_blend, 0.0, delta * 12.0)
		
	# 更新全域相位 (供馬達抓取)
	var phase_x = character_body.global_position.x
	var global_phase = fposmod(phase_x / STRIDE_LENGTH, 1.0)
	l_phase = global_phase
	r_phase = fposmod(global_phase + 0.5, 1.0)
	
	# === 施加生物特定動態力 (Custom Forces) ===
	
	# 1. 脊椎在 X 軸隨機搖擺
	verlet.points[J.SPINE_TOP].accumulated_force.x += facing_dir * 300.0 * walk_blend
	
	# 3. 關節定向偏置 (Joint Bias) 與 手臂反重力 (Anti-gravity)
	var arm_anti_gravity = -680.0 # 抵銷 980，讓向下加速度剩 300
	for j in [J.L_ELBOW, J.R_ELBOW, J.L_HAND, J.R_HAND]:
		verlet.points[j].accumulated_force.y += arm_anti_gravity
		
	verlet.points[J.L_KNEE].accumulated_force.x += facing_dir * 300.0
	verlet.points[J.R_KNEE].accumulated_force.x += facing_dir * 300.0
	# 手肘姿態雕塑：向下壓並微往後收，形成自然的「V」字彎折
	# 為了配合 360 度動態瞄準，後收力道不能太大，只要給予物理引擎一點「彎曲方向」的偏好即可
	# 左手（後手，握較高位置）：自然下垂微後靠
	verlet.points[J.L_ELBOW].accumulated_force.x += -facing_dir * 50.0
	verlet.points[J.L_ELBOW].accumulated_force.y += 100.0
	
	# 右手（前手，握劍柄底端）：手肘較往後收
	verlet.points[J.R_ELBOW].accumulated_force.x += -facing_dir * 100.0
	verlet.points[J.R_ELBOW].accumulated_force.y += 50.0


	

	
	# 執行泛用物理模擬
	verlet.simulate(delta, Vector2(0, 980.0), character_body.global_position.y)
	
			
	queue_redraw()


func _draw() -> void:
	if not verlet or verlet.points.size() < J.COUNT: return
	
	for stick in verlet.sticks:
		if not stick.visible:
			continue
		var pA = (verlet.points[stick.pA].pos - global_position).round()
		var pB = (verlet.points[stick.pB].pos - global_position).round()
		draw_line(pA, pB, Color.WHITE, 1.0)
		
	var head_pos = (verlet.points[J.HEAD_CENTER].pos - global_position).round()
	var rect = Rect2(head_pos - Vector2(4, 4), Vector2(8, 8))
	draw_rect(rect, Color.WHITE, true)