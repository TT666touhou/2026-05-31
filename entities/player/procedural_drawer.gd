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
var walk_blend: float = 0.0

var l_phase: float = 0.0
var r_phase: float = 0.0

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
	
	var main_hand_pivot = sword_rig.get_pivot("MainHand")
	if main_hand_pivot and main_hand_pivot.physics_index != -1:
		# 將玩家的右手與劍的主把手綁死
		verlet.add_stick(J.R_HAND, main_hand_pivot.physics_index, 0.0, 1.0, false)
		
		# 獲取劍尖的索引
		var blade_tip_idx = sword_rig.line_point_map[sword_rig.get_node("Blade")][1]
		
		# 為了產生雙手握持感，將左手綁在劍柄上方 10 像素的位置
		# 我們透過同時約束左手到劍柄(距離10)與劍尖(距離35)，讓左手被迫留在劍身上
		verlet.add_stick(J.L_HAND, main_hand_pivot.physics_index, 10.0, 1.0, false)
		verlet.add_stick(J.L_HAND, blade_tip_idx, 35.0, 1.0, false)
		
		# 設定劍尖的物理屬性：重量大慣性強，衰減慢讓擺動持久
		verlet.points[blade_tip_idx].drag = 0.985
		verlet.points[blade_tip_idx].mass = 2.0
		
		# 將武器的物理控制權交給 WeaponController 處理
		var weapon_controller = sword_rig.get_node_or_null("WeaponController")
		if weapon_controller and weapon_controller.has_method("setup_physics"):
			weapon_controller.setup_physics(verlet, main_hand_pivot.physics_index, blade_tip_idx, facing_dir)


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
	
	var speed = character_body.velocity.x
	if speed > 0.1: facing_dir = 1.0
	elif speed < -0.1: facing_dir = -1.0
	
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
	
	# 2. 左手自然擺動（右手已焊在劍柄，讓劍的物理慣性決定它的位置）
	var hand_force = sin(Engine.get_frames_drawn() * delta * 8.0) * 1500.0 * walk_blend
	verlet.points[J.L_HAND].accumulated_force.x += facing_dir * hand_force
	# 注意：R_HAND 不再施加反相位力，避免把劍柄往後拉扯
	
	# 3. 關節定向偏置 (Joint Bias) 與 手臂反重力 (Anti-gravity)
	var arm_anti_gravity = -680.0 # 抵銷 980，讓向下加速度剩 300
	for j in [J.L_ELBOW, J.R_ELBOW, J.L_HAND, J.R_HAND]:
		verlet.points[j].accumulated_force.y += arm_anti_gravity
		
	verlet.points[J.L_KNEE].accumulated_force.x += facing_dir * 300.0
	verlet.points[J.R_KNEE].accumulated_force.x += facing_dir * 300.0
	# 手肘往前偏置（參考影片逐幀分析：手肘應在肩膀前方，不是往後）
	verlet.points[J.L_ELBOW].accumulated_force.x += facing_dir * 700.0
	verlet.points[J.R_ELBOW].accumulated_force.x += facing_dir * 700.0
	verlet.points[J.L_HAND].accumulated_force.y += 200.0
	verlet.points[J.R_HAND].accumulated_force.y += 200.0
	
	# 4. 劍柄前向偏置：讓劍柄保持在身體前方，劍尖透過慣性自由擺動
	#    sw0 = 索引 J.COUNT = 11（劍柄），加強力讓柄穩在肩前
	if verlet.points.size() > J.COUNT:
		verlet.points[J.COUNT].accumulated_force.x += facing_dir * 1800.0

	
	# 執行泛用物理模擬
	verlet.simulate(delta, Vector2(0, 980.0), character_body.global_position.y)
	
	# Debug 輸出關節座標供 Python 分析
	var debug_str = "DATA:" + str(Engine.get_frames_drawn())
	for i in range(J.COUNT):
		debug_str += ",%.1f,%.1f" % [verlet.points[i].pos.x, verlet.points[i].pos.y]
	print(debug_str)
			
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