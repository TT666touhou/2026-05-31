extends Node2D

enum J {
	HIPS, SPINE_TOP, HEAD_CENTER,
	L_ELBOW, L_HAND,
	R_ELBOW, R_HAND,
	L_KNEE, L_FOOT,
	R_KNEE, R_FOOT,
	COUNT
}

class Point:
	var pos: Vector2
	var old_pos: Vector2
	var locked: bool = false
	
	func _init(p: Vector2):
		pos = p
		old_pos = p

class Stick:
	var pA: int
	var pB: int
	var length: float
	
	func _init(a: int, b: int, l: float):
		pA = a
		pB = b
		length = l

var character_body: CharacterBody2D
var points: Array[Point] = []
var sticks: Array[Stick] = []

const STRIDE_LENGTH = 28.0
const STEP_HEIGHT = 6.0

var facing_dir: float = 1.0
var walk_blend: float = 0.0

func _ready() -> void:
	character_body = get_parent() as CharacterBody2D
	var base_pos = character_body.global_position
	
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
		points.append(Point.new(base_pos + offset))
		
	# 建立棍子約束 (保持 1:2.67 的魔性細長四肢比例)
	sticks.append(Stick.new(J.HIPS, J.SPINE_TOP, 8.0))
	sticks.append(Stick.new(J.SPINE_TOP, J.HEAD_CENTER, 6.0))
	
	sticks.append(Stick.new(J.SPINE_TOP, J.L_ELBOW, 10.0))
	sticks.append(Stick.new(J.L_ELBOW, J.L_HAND, 10.0))
	sticks.append(Stick.new(J.SPINE_TOP, J.R_ELBOW, 10.0))
	sticks.append(Stick.new(J.R_ELBOW, J.R_HAND, 10.0))
	
	sticks.append(Stick.new(J.HIPS, J.L_KNEE, 10.5))
	sticks.append(Stick.new(J.L_KNEE, J.L_FOOT, 10.5))
	sticks.append(Stick.new(J.HIPS, J.R_KNEE, 10.5))
	sticks.append(Stick.new(J.R_KNEE, J.R_FOOT, 10.5))

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
		
	# 計算步伐目標
	var phase_x = character_body.global_position.x
	var global_phase = fposmod(phase_x / STRIDE_LENGTH, 1.0)
	var l_phase = global_phase
	var r_phase = fposmod(global_phase + 0.5, 1.0)
	
	var l_target = character_body.global_position + Vector2(-10, 0) + _get_foot_offset(l_phase, STRIDE_LENGTH) * walk_blend
	var r_target = character_body.global_position + Vector2(10, 0) + _get_foot_offset(r_phase, STRIDE_LENGTH) * walk_blend
	
	var ground_y = character_body.global_position.y
	var time = Time.get_ticks_msec() / 1000.0
	
	# Verlet 積分與浮力 (Buoyancy) 核心機制
	for i in range(J.COUNT):
		var p = points[i]
		if not p.locked:
			var velocity = p.pos - p.old_pos
			p.old_pos = p.pos
			
			var force = Vector2(0, 980.0) # 預設重力
			
			# 針對不同部位施加不同重力/浮力
			if i == J.L_ELBOW or i == J.R_ELBOW or i == J.L_HAND or i == J.R_HAND:
				force.y = 300.0 # 手臂比較輕，輕微下垂即可
			elif i == J.L_KNEE or i == J.R_KNEE or i == J.L_FOOT or i == J.R_FOOT:
				force.y = 980.0 # 腳部正常重力
				
			# 施加 Hips 的跟隨力 (Spring) - 大幅降低，讓骨盆有機會隨著腳步上下顛簸
			if i == J.HIPS:
				var body_target = character_body.global_position + Vector2(0, -21)
				force += (body_target - p.pos) * 600.0
			elif i == J.SPINE_TOP:
				var spine_target = character_body.global_position + Vector2(0, -29)
				force.y += (spine_target.y - p.pos.y) * 600.0
				# 移除絕對平滑的向前拉力，改為微弱的姿態維持力，允許其在 X 軸隨機搖擺
				force.x += facing_dir * 300.0 * walk_blend
				
			elif i == J.HEAD_CENTER:
				# 頭部純粹懸浮，彈簧極度放軟，讓它能跟著下半身「上下左右」瘋狂彈跳
				var head_target = character_body.global_position + Vector2(0, -35)
				force.y += (head_target.y - p.pos.y) * 400.0
				
			if i == J.L_HAND:
				force.x += facing_dir * sin(Engine.get_frames_drawn() * delta * 8.0) * 1500.0 * walk_blend
			if i == J.R_HAND:
				force.x -= facing_dir * sin(Engine.get_frames_drawn() * delta * 8.0) * 1500.0 * walk_blend
				
			# 腳部強大吸附力 (取代 locked = true)
			if i == J.L_FOOT:
				force += (l_target - p.pos) * 800.0
			if i == J.R_FOOT:
				force += (r_target - p.pos) * 800.0
				
			# 關節定向偏置 (Joint Bias) - 轉換為持續的微小力
			if i == J.L_KNEE or i == J.R_KNEE:
				force.x += facing_dir * 300.0
			if i == J.L_ELBOW or i == J.R_ELBOW:
				force.x -= facing_dir * 300.0
			if i == J.L_HAND or i == J.R_HAND:
				force.y += 200.0
				
			velocity += force * delta * delta
			
			# 阻尼 (稍大的阻尼讓動作有果凍感)
			velocity *= 0.90
			
			# 針對頭部和脊椎，賦予極大的慣性 (0.98)，讓它在煞車時能像鐘擺一樣從一側甩到另一側
			if i == J.HEAD_CENTER or i == J.SPINE_TOP:
				velocity *= 1.088 # (抵銷上面的 0.90，讓實際阻尼變成約 0.98)

				
			p.pos += velocity
			
			# 地面剛性碰撞 (Floor Constraints) 與極端摩擦力
			if p.pos.y >= ground_y:
				p.pos.y = ground_y
				p.old_pos.y = p.pos.y # 消除向下的慣性
				# 極端地板摩擦力，讓腳底死死黏住地板，直到被彈簧強力拔起 (0.5 -> 0.99)
				p.old_pos.x = lerp(p.old_pos.x, p.pos.x, 0.99)
			
	# 腳部移動邏輯 (改為彈力牽引而非絕對鎖死，允許腳底因為上半身拉扯而產生魔性滑動)
	# 我們在這裡將目標位置透過極大外力施加到腳步上，而不是強行改寫 pos 和鎖定
	points[J.L_FOOT].locked = false
	points[J.R_FOOT].locked = false
	
	# 約束求解 (多次迭代增加剛性)
	for iter in range(10):
		for stick in sticks:
			var pA = points[stick.pA]
			var pB = points[stick.pB]
			var diff = pA.pos - pB.pos
			var dist = diff.length()
			if dist == 0:
				dist = 0.001
				diff = Vector2(0, 1)
			
			var diff_factor = (stick.length - dist) / dist * 0.5
			var offset = diff * diff_factor
			
			if not pA.locked: pA.pos += offset
			if not pB.locked: pB.pos -= offset
			
	# Debug 輸出關節座標供 Python 分析
	var debug_str = "DATA:" + str(Engine.get_frames_drawn())
	for i in range(J.COUNT):
		debug_str += ",%.1f,%.1f" % [points[i].pos.x, points[i].pos.y]
	print(debug_str)
			
	queue_redraw()

func _draw() -> void:
	if points.size() < J.COUNT: return
	
	for stick in sticks:
		var pA = (points[stick.pA].pos - global_position).round()
		var pB = (points[stick.pB].pos - global_position).round()
		draw_line(pA, pB, Color.WHITE, 1.0)
		
	# 畫頭 (改為實心方塊，大小設為 8x8 完美還原比例，並遮蓋內部的脖子連線)
	var head_pos = (points[J.HEAD_CENTER].pos - global_position).round()
	var rect = Rect2(head_pos - Vector2(4, 4), Vector2(8, 8))
	draw_rect(rect, Color.WHITE, true)