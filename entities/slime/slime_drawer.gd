extends Node2D

var character_body: CharacterBody2D
var verlet

enum S { CENTER, TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT, COUNT }

# Stick indices for dynamic updating
var stick_top: int
var stick_bottom: int
var stick_left: int
var stick_right: int
var stick_centers: Array[int] = []

# 動態比例彈簧變數 (Stretch Spring)
var stretch: float = 1.0
var stretch_velocity: float = 0.0

# 抖動時間累積 (用於噪聲生成)
var jitter_time: float = 0.0

func _ready() -> void:
	character_body = get_parent() as CharacterBody2D
	var base_pos = character_body.global_position
	
	var VerletPhysicsClass = preload("res://physics/verlet/verlet_physics.gd")
	verlet = VerletPhysicsClass.new()
	
	for i in range(S.COUNT):
		var offset = Vector2.ZERO
		match i:
			S.CENTER:       offset = Vector2(0, -11.5)
			S.TOP_LEFT:     offset = Vector2(-15, -23)
			S.TOP_RIGHT:    offset = Vector2(15, -23)
			S.BOTTOM_LEFT:  offset = Vector2(-15, 0)
			S.BOTTOM_RIGHT: offset = Vector2(15, 0)
			
		var p_idx = verlet.add_point(base_pos + offset)
		var p = verlet.points[p_idx]
		p.drag = 0.78  # 收斂阻力：保留黏稠感但不過於飄散
		if i == S.BOTTOM_LEFT or i == S.BOTTOM_RIGHT:
			p.friction = 0.0
			
	# 中心連線
	var diag = Vector2(15.0, 11.5).length()
	stick_centers.append(verlet.add_stick(S.CENTER, S.TOP_LEFT,    diag, 0.4))
	stick_centers.append(verlet.add_stick(S.CENTER, S.TOP_RIGHT,   diag, 0.4))
	stick_centers.append(verlet.add_stick(S.CENTER, S.BOTTOM_LEFT, diag, 0.4))
	stick_centers.append(verlet.add_stick(S.CENTER, S.BOTTOM_RIGHT,diag, 0.4))
	
	# 外圍輪廓連線
	stick_top    = verlet.add_stick(S.TOP_LEFT,    S.TOP_RIGHT,   30.0, 0.4)
	stick_bottom = verlet.add_stick(S.BOTTOM_LEFT, S.BOTTOM_RIGHT,30.0, 0.4)
	stick_left   = verlet.add_stick(S.TOP_LEFT,    S.BOTTOM_LEFT, 23.0, 0.4)
	stick_right  = verlet.add_stick(S.TOP_RIGHT,   S.BOTTOM_RIGHT,23.0, 0.4)
	
	# 馬達極弱，讓各節點有充分自由度，但又不會完全飛散
	verlet.add_motor(S.CENTER,       func(): return character_body.global_position + Vector2(0, -11.5 * stretch),            250.0)
	verlet.add_motor(S.BOTTOM_LEFT,  func(): return character_body.global_position + Vector2(-15.0 / stretch, 0),            250.0)
	verlet.add_motor(S.BOTTOM_RIGHT, func(): return character_body.global_position + Vector2( 15.0 / stretch, 0),            250.0)
	# 頂部馬達加強以防止跳躍傾斜，但仍比底部弱以保留晃動感
	verlet.add_motor(S.TOP_LEFT,  func(): return character_body.global_position + Vector2(-15.0 / stretch, -23.0 * stretch), 200.0)
	verlet.add_motor(S.TOP_RIGHT, func(): return character_body.global_position + Vector2( 15.0 / stretch, -23.0 * stretch), 200.0)

func _physics_process(delta: float) -> void:
	if not character_body: return
	
	jitter_time += delta
	
	# ── 拉伸目標：速度越快拉越長，最大 2.0 倍 ──
	var target_stretch: float
	if not character_body.is_on_floor():
		target_stretch = 1.0 + clamp(abs(character_body.velocity.y) / 280.0, 0.0, 1.0)
	else:
		target_stretch = 1.0
		
	# ── 偏軟彈簧 + 低阻尼：明顯震盪但不瘋狂 ──
	var tension = (target_stretch - stretch) * 35.0
	var damping = stretch_velocity * 2.2
	
	stretch_velocity += (tension - damping) * delta
	stretch += stretch_velocity * delta
	stretch = clamp(stretch, 0.3, 2.5)
	
	# ── 面積保持不變 (Area Preservation) ──
	var w = 30.0 / stretch
	var h = 23.0 * stretch
	var dx = w / 2.0
	var dy = h / 2.0
	var center_dist = sqrt(dx*dx + dy*dy)
	
	verlet.sticks[stick_top].length    = w
	verlet.sticks[stick_bottom].length = w
	verlet.sticks[stick_left].length   = h
	verlet.sticks[stick_right].length  = h
	for idx in stick_centers:
		verlet.sticks[idx].length = center_dist
	
	# ── 有機抖動噪聲：頂部純 Y 軸避免傾斜，底部允許微量 X ──
	var jitter_y = 45.0 if not character_body.is_on_floor() else 18.0
	var jitter_x_bot = 20.0 if not character_body.is_on_floor() else 8.0
	
	# 頂部：左右用相同 Y 幅度、相反相位，產生上下抖動而非旋轉
	var top_y_l = cos(jitter_time * 5.1) * jitter_y
	var top_y_r = cos(jitter_time * 5.1 + PI) * jitter_y  # 相反相位 = 頂邊交替波動
	verlet.points[S.TOP_LEFT].accumulated_force.y  += top_y_l
	verlet.points[S.TOP_RIGHT].accumulated_force.y += top_y_r
	
	# 底部：輕微 X+Y 抖動，對稱以避免橫向漂移
	verlet.points[S.BOTTOM_LEFT].accumulated_force  += Vector2(-sin(jitter_time * 6.4) * jitter_x_bot, cos(jitter_time * 7.1) * jitter_y * 0.5)
	verlet.points[S.BOTTOM_RIGHT].accumulated_force += Vector2( sin(jitter_time * 6.4) * jitter_x_bot, cos(jitter_time * 7.1 + 0.5) * jitter_y * 0.5)
	
	# ── 落地衝擊脈衝 (收斂) ──
	if character_body.is_on_floor() and abs(character_body.velocity.y) < 5.0 and stretch > 1.2:
		verlet.points[S.TOP_LEFT].accumulated_force.y  += 3500.0
		verlet.points[S.TOP_RIGHT].accumulated_force.y += 3500.0
		
	verlet.simulate(delta, Vector2(0, 980.0), character_body.global_position.y)
	queue_redraw()

func _draw() -> void:
	if not verlet or verlet.points.size() < S.COUNT: return
	
	var pts = PackedVector2Array()
	pts.append(verlet.points[S.TOP_LEFT].pos    - global_position)
	pts.append(verlet.points[S.TOP_RIGHT].pos   - global_position)
	pts.append(verlet.points[S.BOTTOM_RIGHT].pos - global_position)
	pts.append(verlet.points[S.BOTTOM_LEFT].pos  - global_position)
	pts.append(pts[0]) # 閉合
	
	# 空心矩形 (綠色外框線，1.0px 與 player 一致)
	draw_polyline(pts, Color(0.2, 0.8, 0.4, 1.0), 1.0)
