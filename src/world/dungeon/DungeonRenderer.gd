# DungeonRenderer.gd
# 用程序繪製（draw_rect / draw_line / draw_polygon）在 Node2D 上直接渲染地下城地圖
# 精心調校的程序化向量渲染，與 ProceduralDrawer 的簡約棍人哲學高度契合，兼具極致立體光影效果。

class_name DungeonRenderer
extends Node2D

# ── 繪製常數 ────────────────────────────────────────────
const TILE_SIZE := 64

# 顏色定義（Darkwood 考察：飽和度低、深沉、木質與石材的質感）
const COLOR_FLOOR_BASE   := Color(0.38, 0.32, 0.26, 1.0)   # 腐木板底色
const COLOR_FLOOR_VAR1   := Color(0.33, 0.27, 0.22, 1.0)   # 暗褐色木板
const COLOR_FLOOR_VAR2   := Color(0.42, 0.36, 0.30, 1.0)   # 稍亮木板
const COLOR_FLOOR_HIGHLIGHT := Color(0.48, 0.42, 0.36, 0.25) # 木板邊框亮部高光
const COLOR_NAIL         := Color(0.12, 0.10, 0.08, 0.70)  # 固定木板的鐵釘顏色

const COLOR_WALL_BASE    := Color(0.26, 0.22, 0.18, 1.0)   # 厚石牆底層
const COLOR_WALL_TOP     := Color(0.48, 0.44, 0.40, 1.0)   # 牆壁頂面亮部高光（受光面）
const COLOR_WALL_SHADOW  := Color(0.14, 0.12, 0.10, 1.0)   # 牆壁深色縫隙與暗面
const COLOR_WALL_BRICK_VAR := Color(0.06, 0.05, 0.04, 0.15) # 磚塊色差擾動色

const COLOR_CRACK        := Color(0.10, 0.08, 0.07, 0.75)  # 裂紋深處
const COLOR_GROUT        := Color(0.14, 0.11, 0.09, 0.90)  # 木板/磚石深層縫隙
const COLOR_MOSS         := Color(0.18, 0.24, 0.14, 0.45)  # 陰濕青苔顏色

# 房間類型顏色點（DEBUG 用）
const DEBUG_ROOM_COLORS = {
	"start":    Color(0.2, 0.9, 0.2, 0.10),
	"elite":    Color(0.7, 0.2, 0.9, 0.10),
	"treasure": Color(0.9, 0.8, 0.1, 0.10),
	"shop":     Color(0.2, 0.5, 0.9, 0.10),
	"boss":     Color(0.9, 0.1, 0.1, 0.10),
	"normal":   Color(0.0, 0.0, 0.0, 0.0),
}

# ── 資料 ────────────────────────────────────────────────
var gen: DungeonGenerator = null
var show_debug_rooms: bool = false

# 碰撞層與遮光罩集合
var wall_bodies: Array[StaticBody2D] = []
var light_occluders: Array[LightOccluder2D] = []
var wall_renderer: Node2D = null

func _ready() -> void:
	wall_renderer = Node2D.new()
	wall_renderer.name = "WallRenderer"
	wall_renderer.light_mask = 8 # Layer 4 (牆頂亮部遮罩)
	add_child(wall_renderer)
	wall_renderer.draw.connect(_draw_walls_layer)

# ── 入口 ────────────────────────────────────────────────
func render(generator: DungeonGenerator) -> void:
	gen = generator
	_clear_walls()
	_build_wall_colliders()
	queue_redraw()
	if wall_renderer:
		wall_renderer.queue_redraw()

func _clear_walls() -> void:
	for body in wall_bodies:
		if is_instance_valid(body):
			body.queue_free()
	wall_bodies.clear()
	for occ in light_occluders:
		if is_instance_valid(occ):
			occ.queue_free()
	light_occluders.clear()

# ── 建立牆壁碰撞與遮光（水平合批優化）───────────────────
func _build_wall_colliders() -> void:
	if gen == null:
		return
	
	for y in gen.map_height:
		var start_x: int = -1
		for x in range(gen.map_width + 1):
			var is_w = x < gen.map_width and gen.is_wall(x, y)
			if is_w and start_x == -1:
				start_x = x
			elif not is_w and start_x != -1:
				_create_wall_body(start_x, y, x - start_x, 1)
				start_x = -1

func _create_wall_body(tile_x: int, tile_y: int, w: int, h: int) -> void:
	# 1. 物理碰撞體 (StaticBody2D)
	var body = StaticBody2D.new()
	body.collision_layer = 1  # World layer
	body.collision_mask  = 0
	
	var shape = CollisionShape2D.new()
	var rect  = RectangleShape2D.new()
	rect.size = Vector2(w * TILE_SIZE, h * TILE_SIZE)
	shape.shape = rect
	shape.position = Vector2(w * TILE_SIZE / 2.0, h * TILE_SIZE / 2.0)
	
	body.add_child(shape)
	body.position = Vector2(tile_x * TILE_SIZE, tile_y * TILE_SIZE)
	add_child(body)
	wall_bodies.append(body)
	
	# 2. 視野光線遮蔽體 (LightOccluder2D)
	var occ = LightOccluder2D.new()
	var poly = OccluderPolygon2D.new()
	poly.closed = true
	var px = float(tile_x * TILE_SIZE)
	var py = float(tile_y * TILE_SIZE)
	var pw = float(w * TILE_SIZE)
	var ph = float(TILE_SIZE)
	poly.polygon = PackedVector2Array([
		Vector2(px,      py),
		Vector2(px + pw, py),
		Vector2(px + pw, py + ph),
		Vector2(px,      py + ph)
	])
	occ.occluder = poly
	occ.occluder_light_mask = 7 # 遮擋 Light Layer 1, 2, 3
	add_child(occ)
	light_occluders.append(occ)

# ── _draw 主繪製 ────────────────────────────────────────
func _draw() -> void:
	if gen == null:
		return
	
	_draw_floors()
	_draw_wall_ao()
	
	if show_debug_rooms:
		_draw_debug_rooms()

# ── 地板繪製（精緻木紋地板與立體倒角）────────────────────
func _draw_floors() -> void:
	var rng_local = RandomNumberGenerator.new()
	
	for y in gen.map_height:
		for x in gen.map_width:
			if not gen.is_floor(x, y):
				continue
			
			var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			
			# 用坐標決定固定的隨機亂數種子，防每影格抖動
			rng_local.seed = x * 8831 + y * 4909
			var roll = rng_local.randf()
			
			# 地板底色微小隨機變體
			var col: Color
			if roll < 0.55:
				col = COLOR_FLOOR_BASE
			elif roll < 0.80:
				col = COLOR_FLOOR_VAR1
			else:
				col = COLOR_FLOOR_VAR2
			
			# 繪製主格底色
			draw_rect(Rect2(world_pos, Vector2(TILE_SIZE, TILE_SIZE)), col)
			
			# ── 繪製四塊拼接木板 ──
			var plank_h = TILE_SIZE / 4.0
			for i in range(4):
				var py = world_pos.y + i * plank_h
				var rng_plank = RandomNumberGenerator.new()
				rng_plank.seed = x * 1000 + y * 10 + i
				
				# 隨機化單塊木板顏色，營造年久失修拼接感
				var plank_col_mod = col * Color(1.0 + rng_plank.randf_range(-0.06, 0.06), 1.0 + rng_plank.randf_range(-0.06, 0.06), 1.0 + rng_plank.randf_range(-0.06, 0.06), 1.0)
				draw_rect(Rect2(world_pos.x, py, TILE_SIZE, plank_h), plank_col_mod)
				
				# 木板頂部高光倒角，底部深色陰影線，突顯浮雕立體感
				draw_line(Vector2(world_pos.x, py), Vector2(world_pos.x + TILE_SIZE, py), COLOR_FLOOR_HIGHLIGHT, 1.0)
				draw_line(Vector2(world_pos.x, py + plank_h), Vector2(world_pos.x + TILE_SIZE, py + plank_h), COLOR_GROUT, 1.2)
				
				# ── 畫鐵釘 (Nails) ──
				# 每一片木板兩端均釘有防鬆動鐵釘，細節加分
				if rng_plank.randf() > 0.15:
					var nail1_pos = Vector2(world_pos.x + rng_plank.randf_range(3, 6), py + plank_h / 2.0)
					var nail2_pos = Vector2(world_pos.x + TILE_SIZE - rng_plank.randf_range(3, 6), py + plank_h / 2.0)
					draw_circle(nail1_pos, 1.8, COLOR_NAIL)
					draw_circle(nail2_pos, 1.8, COLOR_NAIL)
				
				# ── 畫木板紋理 (Wood Grain) ──
				# 隨機產生優美彎曲的木紋線，而非死板直線
				if rng_plank.randf() > 0.40:
					var grain_y = py + rng_plank.randf_range(3, plank_h - 3)
					var ctrl_offset = rng_plank.randf_range(-3, 3)
					# 利用中間點偏移繪製平滑折線模擬弧形年輪
					var points = PackedVector2Array([
						Vector2(world_pos.x, grain_y),
						Vector2(world_pos.x + TILE_SIZE * 0.3, grain_y + ctrl_offset),
						Vector2(world_pos.x + TILE_SIZE * 0.7, grain_y - ctrl_offset),
						Vector2(world_pos.x + TILE_SIZE, grain_y)
					])
					draw_polyline(points, COLOR_CRACK * Color(1, 1, 1, 0.45), 1.0)
			
			# 隨機大裂痕與刮踏痕跡
			if roll > 0.88:
				var c_x = world_pos.x + rng_local.randi_range(12, TILE_SIZE - 12)
				var c_y = world_pos.y + rng_local.randi_range(12, TILE_SIZE - 12)
				var length = rng_local.randi_range(10, 24)
				var ang = rng_local.randf() * TAU
				var end_pt = Vector2(c_x + cos(ang) * length, c_y + sin(ang) * length)
				draw_line(Vector2(c_x, c_y), end_pt, COLOR_CRACK, 1.5)

# ── 牆壁柔和環境陰影 (Soft Gradient Ambient Occlusion) ──
# 使用頂點顏色插值 (Polygon vertex color interpolation) 畫出完美的線性漸層陰影，徹底抹除格狀鋸齒感
func _draw_wall_ao() -> void:
	var shadow_w: float = 24.0 # 陰影寬度 (像素)
	var col_dark = Color(0, 0, 0, 0.48)
	var col_fade = Color(0, 0, 0, 0.0)
	
	for y in gen.map_height:
		for x in gen.map_width:
			if not gen.is_wall(x, y):
				continue
				
			var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			
			# 向南面臨地板：向下漸層陰影
			if gen.is_floor(x, y + 1):
				var px = world_pos.x
				var py = world_pos.y + TILE_SIZE
				var verts = PackedVector2Array([
					Vector2(px, py),
					Vector2(px + TILE_SIZE, py),
					Vector2(px + TILE_SIZE, py + shadow_w),
					Vector2(px, py + shadow_w)
				])
				var colors = PackedColorArray([col_dark, col_dark, col_fade, col_fade])
				draw_polygon(verts, colors)
				
			# 向北面臨地板：向上漸層陰影
			if gen.is_floor(x, y - 1):
				var px = world_pos.x
				var py = world_pos.y
				var verts = PackedVector2Array([
					Vector2(px, py),
					Vector2(px + TILE_SIZE, py),
					Vector2(px + TILE_SIZE, py - shadow_w),
					Vector2(px, py - shadow_w)
				])
				var colors = PackedColorArray([col_dark, col_dark, col_fade, col_fade])
				draw_polygon(verts, colors)
				
			# 向東面臨地板：向右漸層陰影
			if gen.is_floor(x + 1, y):
				var px = world_pos.x + TILE_SIZE
				var py = world_pos.y
				var verts = PackedVector2Array([
					Vector2(px, py),
					Vector2(px, py + TILE_SIZE),
					Vector2(px + shadow_w, py + TILE_SIZE),
					Vector2(px + shadow_w, py)
				])
				var colors = PackedColorArray([col_dark, col_dark, col_fade, col_fade])
				draw_polygon(verts, colors)
				
			# 向西面臨地板：向左漸層陰影
			if gen.is_floor(x - 1, y):
				var px = world_pos.x
				var py = world_pos.y
				var verts = PackedVector2Array([
					Vector2(px, py),
					Vector2(px, py + TILE_SIZE),
					Vector2(px - shadow_w, py + TILE_SIZE),
					Vector2(px - shadow_w, py)
				])
				var colors = PackedColorArray([col_dark, col_dark, col_fade, col_fade])
				draw_polygon(verts, colors)

# ── 牆壁繪製（3D 立體砌磚與拐角裝飾柱）───────────────────
func _draw_walls_layer() -> void:
	if gen == null or not wall_renderer:
		return
		
	for y in gen.map_height:
		for x in gen.map_width:
			if not gen.is_wall(x, y):
				continue
				
			var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			
			# ── 牆面本體底色 ──
			wall_renderer.draw_rect(Rect2(world_pos, Vector2(TILE_SIZE, TILE_SIZE)), COLOR_WALL_BASE)
			
			# 畫牆面立體浮雕磚石 (分三層磚塊)
			var wall_rng = RandomNumberGenerator.new()
			wall_rng.seed = x * 7753 + y * 8461
			
			var brick_h = TILE_SIZE / 3.0
			for b in range(3):
				var by = world_pos.y + b * brick_h
				var rng_brick = RandomNumberGenerator.new()
				rng_brick.seed = x * 1000 + y * 100 + b
				
				# 磚塊左右接縫偏移（錯開磚縫以顯自然）
				var joints = []
				if b == 0:
					joints = [0.0, 0.45 * TILE_SIZE, TILE_SIZE]
				elif b == 1:
					joints = [0.0, 0.25 * TILE_SIZE, 0.75 * TILE_SIZE, TILE_SIZE]
				else:
					joints = [0.0, 0.55 * TILE_SIZE, TILE_SIZE]
					
				# 繪製單個磚頭的倒角高光與陰影
				for j in range(joints.size() - 1):
					var j_start = joints[j]
					var j_end = joints[j+1]
					var b_width = j_end - j_start
					var bx = world_pos.x + j_start
					
					var brick_rect = Rect2(bx, by, b_width, brick_h)
					
					# 磚塊隨機亮度擾動
					var brick_col = COLOR_WALL_BASE + COLOR_WALL_BRICK_VAR * rng_brick.randf_range(-1.2, 1.2)
					wall_renderer.draw_rect(brick_rect, brick_col)
					
					# 磚縫深色陰影線
					wall_renderer.draw_rect(brick_rect, COLOR_WALL_SHADOW, false, 1.2)
					
					# 磚塊受光高光倒角 (頂面亮，左面稍亮，營造3D雕刻浮雕效果)
					wall_renderer.draw_line(Vector2(bx, by), Vector2(bx + b_width, by), COLOR_WALL_TOP * Color(1,1,1,0.35), 1.0)
					wall_renderer.draw_line(Vector2(bx, by), Vector2(bx, by + brick_h), COLOR_WALL_TOP * Color(1,1,1,0.20), 1.0)
			
			# ── 牆角立體裝飾柱 (Pillar Caps) ──
			# 偵測是否為房間角落的凸角，如果是則繪製華麗的柱頭以豐富地形結構
			var is_se_corner = gen.is_floor(x + 1, y) and gen.is_floor(x, y + 1)
			var is_sw_corner = gen.is_floor(x - 1, y) and gen.is_floor(x, y + 1)
			var is_ne_corner = gen.is_floor(x + 1, y) and gen.is_floor(x, y - 1)
			var is_nw_corner = gen.is_floor(x - 1, y) and gen.is_floor(x, y - 1)
			
			var p_radius = 8.0
			if is_se_corner:
				var p_pos = world_pos + Vector2(TILE_SIZE, TILE_SIZE)
				wall_renderer.draw_circle(p_pos, p_radius, COLOR_WALL_TOP)
				wall_renderer.draw_circle(p_pos, p_radius - 2, COLOR_WALL_BASE)
				wall_renderer.draw_circle(p_pos, p_radius - 4, COLOR_WALL_SHADOW)
			elif is_sw_corner:
				var p_pos = world_pos + Vector2(0, TILE_SIZE)
				wall_renderer.draw_circle(p_pos, p_radius, COLOR_WALL_TOP)
				wall_renderer.draw_circle(p_pos, p_radius - 2, COLOR_WALL_BASE)
				wall_renderer.draw_circle(p_pos, p_radius - 4, COLOR_WALL_SHADOW)
			elif is_ne_corner:
				var p_pos = world_pos + Vector2(TILE_SIZE, 0)
				wall_renderer.draw_circle(p_pos, p_radius, COLOR_WALL_TOP)
				wall_renderer.draw_circle(p_pos, p_radius - 2, COLOR_WALL_BASE)
				wall_renderer.draw_circle(p_pos, p_radius - 4, COLOR_WALL_SHADOW)
			elif is_nw_corner:
				var p_pos = world_pos
				wall_renderer.draw_circle(p_pos, p_radius, COLOR_WALL_TOP)
				wall_renderer.draw_circle(p_pos, p_radius - 2, COLOR_WALL_BASE)
				wall_renderer.draw_circle(p_pos, p_radius - 4, COLOR_WALL_SHADOW)
			
			# ── 牆頂凸緣亮邊 (由南面看過去的受光面，覆蓋在最上層) ──
			if gen.is_floor(x, y + 1):
				wall_renderer.draw_rect(Rect2(world_pos.x, world_pos.y, TILE_SIZE, 5), COLOR_WALL_TOP)
				wall_renderer.draw_rect(Rect2(world_pos.x, world_pos.y + TILE_SIZE - 4, TILE_SIZE, 4), COLOR_WALL_SHADOW)
			if gen.is_floor(x + 1, y):
				wall_renderer.draw_rect(Rect2(world_pos.x + TILE_SIZE - 3, world_pos.y, 3, TILE_SIZE), COLOR_WALL_SHADOW)
			if gen.is_floor(x - 1, y):
				wall_renderer.draw_rect(Rect2(world_pos.x, world_pos.y, 3, TILE_SIZE), COLOR_WALL_SHADOW)
				
			# 隨機潮濕發霉/苔蘚
			if wall_rng.randf() > 0.82 and gen.is_floor(x, y + 1):
				var moss_w = wall_rng.randi_range(12, 36)
				var moss_x = wall_rng.randi_range(0, TILE_SIZE - moss_w)
				wall_renderer.draw_rect(Rect2(world_pos + Vector2(moss_x, TILE_SIZE - 6), Vector2(moss_w, 4)), COLOR_MOSS)

# ── DEBUG：房間類型標記 ─────────────────────────────────
func _draw_debug_rooms() -> void:
	for rd in gen.rooms:
		var col = DEBUG_ROOM_COLORS.get(rd.type, Color.TRANSPARENT)
		if col.a > 0:
			draw_rect(
				Rect2(
					Vector2(rd.rect.position.x * TILE_SIZE, rd.rect.position.y * TILE_SIZE),
					Vector2(rd.rect.size.x * TILE_SIZE, rd.rect.size.y * TILE_SIZE)
				),
				col
			)
