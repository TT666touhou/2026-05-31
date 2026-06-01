# DungeonRenderer.gd
# 用程序繪製（draw_rect / draw_line）在 Node2D 上直接渲染地下城地圖
# 不依賴任何外部貼圖，與 ProceduralDrawer 的棍人哲學一致

class_name DungeonRenderer
extends Node2D

# ── 繪製常數 ────────────────────────────────────────────
const TILE_SIZE := 64

# ── 顏色與細節常量 ──────────────────────────────────────
const COLOR_FLOOR_BASE   := Color(0.36, 0.30, 0.24, 1.0)   # 腐爛木地板底色
const COLOR_FLOOR_VAR1   := Color(0.28, 0.23, 0.18, 1.0)   # 較深偏泥污色
const COLOR_FLOOR_VAR2   := Color(0.42, 0.35, 0.29, 1.0)   # 較淺乾燥色
const COLOR_PLANK_HIGHLIGHT := Color(0.55, 0.48, 0.40, 0.15) # 板頂亮線 (Bevel Top)
const COLOR_PLANK_SHADOW  := Color(0.12, 0.09, 0.07, 0.45) # 板底溝線 (Bevel Bottom)
const COLOR_GROUT        := Color(0.14, 0.11, 0.09, 0.8)   # 木板縫隙線
const COLOR_NAIL         := Color(0.18, 0.16, 0.14, 0.85)  # 鐵釘色
const COLOR_NAIL_LIT     := Color(0.60, 0.55, 0.50, 0.25)  # 鐵釘高光

const COLOR_WALL_BASE    := Color(0.22, 0.20, 0.18, 1.0)   # 磚牆縫隙底色 (Mortar)
const COLOR_STONE_BASE   := Color(0.35, 0.32, 0.29, 1.0)   # 石磚主體色
const COLOR_STONE_VAR1   := Color(0.30, 0.27, 0.24, 1.0)   # 深色石磚
const COLOR_STONE_VAR2   := Color(0.40, 0.37, 0.34, 1.0)   # 淺色石磚
const COLOR_STONE_HIGHLIGHT := Color(0.58, 0.55, 0.52, 0.25) # 石磚左/上斜切高光
const COLOR_STONE_SHADOW    := Color(0.14, 0.12, 0.11, 0.50) # 石磚右/下斜切暗影

const COLOR_CRACK        := Color(0.08, 0.06, 0.05, 0.9)   # 深裂紋縫
const COLOR_CRACK_LIT    := Color(0.65, 0.60, 0.55, 0.25)  # 裂紋受光邊亮線

const COLOR_MOSS_DARK    := Color(0.14, 0.18, 0.10, 0.75)  # 青苔深部
const COLOR_MOSS_LIGHT   := Color(0.25, 0.32, 0.18, 0.60)  # 青苔亮部

# 房間類型顏色點（DEBUG 用，正式版關掉）
const DEBUG_ROOM_COLORS = {
	"start":    Color(0.2, 0.9, 0.2, 0.15),
	"elite":    Color(0.7, 0.2, 0.9, 0.15),
	"treasure": Color(0.9, 0.8, 0.1, 0.15),
	"shop":     Color(0.2, 0.5, 0.9, 0.15),
	"boss":     Color(0.9, 0.1, 0.1, 0.15),
	"normal":   Color(0.0, 0.0, 0.0, 0.0),
}

# ── 資料 ────────────────────────────────────────────────
var gen: DungeonGenerator = null
var show_debug_rooms: bool = false

# 碰撞層（牆壁的 StaticBody2D 集合）
var wall_bodies: Array[StaticBody2D] = []
# 光線遮擋體集合
var light_occluders: Array[LightOccluder2D] = []

var wall_renderer: Node2D = null

func _ready() -> void:
	wall_renderer = Node2D.new()
	wall_renderer.name = "WallRenderer"
	wall_renderer.light_mask = 8 # Layer 4
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

# ── 建立牆壁碰撞體 ──────────────────────────────────────
# 用合批的方式建立：連續水平牆合併成一個長矩形
func _build_wall_colliders() -> void:
	if gen == null:
		return
	
	# 每行掃描，合併連續牆壁
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
	# ── 碰撞體 ────────────────────────────────────────────
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
	
	# ── 光線遮擋體（讓 PointLight2D 的光線被牆壁截斷）────
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
	occ.occluder_light_mask = 7
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

# ── 地板繪製 ────────────────────────────────────────────
func _draw_floors() -> void:
	var rng_local = RandomNumberGenerator.new()
	
	for y in gen.map_height:
		for x in gen.map_width:
			if not gen.is_floor(x, y):
				continue
			
			var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			
			# 用座標決定基礎顏色與變體（固定，不每幀重算）
			rng_local.seed = x * 9137 + y * 3517
			var roll = rng_local.randf()
			
			var col: Color
			if roll < 0.60:
				col = COLOR_FLOOR_BASE
			elif roll < 0.80:
				col = COLOR_FLOOR_VAR1
			else:
				col = COLOR_FLOOR_VAR2
			
			# ── 繪製 4 塊獨立木地板 (Planks) ──
			var plank_h = TILE_SIZE / 4.0
			for p in range(4):
				var p_rng = RandomNumberGenerator.new()
				p_rng.seed = x * 7919 + y * 5113 + p * 9137
				
				# 隨機微調每塊木板的顏色以增加層次
				var p_col = col
				var c_shift = p_rng.randf_range(-0.04, 0.04)
				p_col.r = clamp(p_col.r + c_shift, 0.0, 1.0)
				p_col.g = clamp(p_col.g + c_shift, 0.0, 1.0)
				p_col.b = clamp(p_col.b + c_shift, 0.0, 1.0)
				
				var plank_rect = Rect2(world_pos.x, world_pos.y + p * plank_h, TILE_SIZE, plank_h)
				draw_rect(plank_rect, p_col)
				
				# ── 繪製細緻波浪木紋 ──
				var grain_y_start = plank_rect.position.y + p_rng.randf_range(3.0, plank_h - 3.0)
				var grain_points = PackedVector2Array()
				var segments = 6
				var seg_w = TILE_SIZE / float(segments)
				var freq = p_rng.randf_range(0.04, 0.12)
				var amp = p_rng.randf_range(0.8, 2.5)
				var phase = p_rng.randf() * TAU
				
				for s in range(segments + 1):
					var gx = world_pos.x + s * seg_w
					var gy = grain_y_start + sin(s * freq * seg_w + phase) * amp
					# 限制木紋在單塊木板內
					gy = clamp(gy, plank_rect.position.y + 1, plank_rect.position.y + plank_h - 1)
					grain_points.append(Vector2(gx, gy))
				draw_polyline(grain_points, COLOR_CRACK * Color(1, 1, 1, 0.18), 1.0)
				
				# ── 木板上下邊緣的立體斜切線 ──
				# 頂部亮邊
				draw_line(
					Vector2(plank_rect.position.x, plank_rect.position.y),
					Vector2(plank_rect.position.x + TILE_SIZE, plank_rect.position.y),
					COLOR_PLANK_HIGHLIGHT, 1.0
				)
				# 底部暗線
				draw_line(
					Vector2(plank_rect.position.x, plank_rect.position.y + plank_h),
					Vector2(plank_rect.position.x + TILE_SIZE, plank_rect.position.y + plank_h),
					COLOR_PLANK_SHADOW, 1.0
				)
				
				# ── 繪製固定鐵釘 (Nails) ──
				# 左端與右端各打一顆小鐵釘
				var nail_lx = plank_rect.position.x + p_rng.randf_range(4.0, 7.0)
				var nail_rx = plank_rect.position.x + TILE_SIZE - p_rng.randf_range(4.0, 7.0)
				var nail_y = plank_rect.position.y + plank_h / 2.0 + p_rng.randf_range(-1.0, 1.0)
				
				# 左釘
				draw_circle(Vector2(nail_lx, nail_y), 1.2, COLOR_NAIL)
				draw_circle(Vector2(nail_lx - 0.4, nail_y - 0.4), 0.5, COLOR_NAIL_LIT)
				# 右釘
				draw_circle(Vector2(nail_rx, nail_y), 1.2, COLOR_NAIL)
				draw_circle(Vector2(nail_rx - 0.4, nail_y - 0.4), 0.5, COLOR_NAIL_LIT)
			
			# ── 隨機發霉污垢與液體污漬 ──
			if roll > 0.65:
				var num_spots = rng_local.randi_range(1, 2)
				for s in num_spots:
					var spot_pos = world_pos + Vector2(rng_local.randf_range(10, TILE_SIZE - 10), rng_local.randf_range(10, TILE_SIZE - 10))
					var spot_rad = rng_local.randf_range(4.0, 10.0)
					# 繪製略帶透明的髒污圈
					draw_circle(spot_pos, spot_rad, Color(0.06, 0.05, 0.04, 0.32))
			
			# ── 偶發木板深層龜裂 ──
			if roll > 0.90:
				_draw_crack(world_pos, rng_local)

# ── 隨機裂縫細節 ────────────────────────────────────────
func _draw_crack(world_pos: Vector2, local_rng: RandomNumberGenerator) -> void:
	var crack_x = world_pos.x + local_rng.randf_range(10, TILE_SIZE - 10)
	var crack_y = world_pos.y + local_rng.randf_range(10, TILE_SIZE - 10)
	var length  = local_rng.randf_range(8, 22)
	var angle   = local_rng.randf() * TAU
	var end_pt  = Vector2(crack_x + cos(angle) * length, crack_y + sin(angle) * length)
	
	# 深處裂縫線
	draw_line(Vector2(crack_x, crack_y), end_pt, COLOR_CRACK, 1.2)
	# 邊緣反光線，增加厚度感
	draw_line(Vector2(crack_x + 0.5, crack_y + 0.5), end_pt + Vector2(0.5, 0.5), COLOR_CRACK_LIT, 0.8)

# ── 牆壁與 AO 陰影繪製 ──────────────────────────────────
func _draw_wall_ao() -> void:
	for y in gen.map_height:
		for x in gen.map_width:
			if not gen.is_wall(x, y):
				continue
			
			var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			
			# ── 繪製環境光遮蔽 (AO) 漸層陰影到相鄰地板上 (細分為 10 層，極致絲滑) ──
			for i in range(10):
				var dist = i * 2.0
				var alpha = 0.48 * (1.0 - i / 10.0) # 隨距離淡出
				var s_col = Color(0.0, 0.0, 0.0, alpha)
				
				# 向南鄰接地板
				if gen.is_floor(x, y + 1):
					draw_rect(Rect2(world_pos.x, world_pos.y + TILE_SIZE + dist, TILE_SIZE, 2.0), s_col)
				# 向北鄰接地板
				if gen.is_floor(x, y - 1):
					draw_rect(Rect2(world_pos.x, world_pos.y - dist - 2.0, TILE_SIZE, 2.0), s_col)
				# 向東鄰接地板
				if gen.is_floor(x + 1, y):
					draw_rect(Rect2(world_pos.x + TILE_SIZE + dist, world_pos.y, 2.0, TILE_SIZE), s_col)
				# 向西鄰接地板
				if gen.is_floor(x - 1, y):
					draw_rect(Rect2(world_pos.x - dist - 2.0, world_pos.y, 2.0, TILE_SIZE), s_col)

# ── 牆面程序繪製 ────────────────────────────────────────
func _draw_walls_layer() -> void:
	if gen == null or not wall_renderer:
		return
		
	for y in gen.map_height:
		for x in gen.map_width:
			if not gen.is_wall(x, y):
				continue
				
			var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			
			# ── 牆面灰泥底色 ──
			wall_renderer.draw_rect(Rect2(world_pos, Vector2(TILE_SIZE, TILE_SIZE)), COLOR_WALL_BASE)
			
			# ── 繪製 3 行立體石磚 (Stone Masonry) ──
			var brick_heights = [21.0, 21.0, 22.0]
			var current_y = 0.0
			
			for r in range(3):
				var bh = brick_heights[r]
				var bh_f = bh - 1.0 # 留出 1px 的水平灰縫
				
				var row_rng = RandomNumberGenerator.new()
				row_rng.seed = x * 8461 + y * 9733 + r * 1543
				
				# 隨機打斷垂直磚縫 (以亂數決定分割點)
				var split = row_rng.randf_range(16.0, 48.0)
				var brick_widths = [split, TILE_SIZE - split]
				var current_x = 0.0
				
				for b in range(2):
					var bw = brick_widths[b]
					var bw_f = bw - 1.0 # 留出 1px 的垂直灰縫
					
					var brick_rect = Rect2(world_pos.x + current_x, world_pos.y + current_y, bw_f, bh_f)
					
					# 選定石磚本體顏色變體
					var b_col = COLOR_STONE_BASE
					var col_roll = row_rng.randf()
					if col_roll < 0.32:
						b_col = COLOR_STONE_VAR1
					elif col_roll < 0.64:
						b_col = COLOR_STONE_VAR2
						
					# 石磚本體
					wall_renderer.draw_rect(brick_rect, b_col)
					
					# ── 3D 斜角高光與暗影 (Bevel Overlay) ──
					# 左邊與頂部亮邊
					wall_renderer.draw_line(
						Vector2(brick_rect.position.x, brick_rect.position.y),
						Vector2(brick_rect.position.x + brick_rect.size.x, brick_rect.position.y),
						COLOR_STONE_HIGHLIGHT, 1.0
					)
					wall_renderer.draw_line(
						Vector2(brick_rect.position.x, brick_rect.position.y),
						Vector2(brick_rect.position.x, brick_rect.position.y + brick_rect.size.y),
						COLOR_STONE_HIGHLIGHT, 1.0
					)
					# 右邊與底部暗邊
					wall_renderer.draw_line(
						Vector2(brick_rect.position.x, brick_rect.position.y + brick_rect.size.y),
						Vector2(brick_rect.position.x + brick_rect.size.x, brick_rect.position.y + brick_rect.size.y),
						COLOR_STONE_SHADOW, 1.0
					)
					wall_renderer.draw_line(
						Vector2(brick_rect.position.x + brick_rect.size.x, brick_rect.position.y),
						Vector2(brick_rect.position.x + brick_rect.size.x, brick_rect.position.y + brick_rect.size.y),
						COLOR_STONE_SHADOW, 1.0
					)
					
					# ── 石磚上的微細碎裂紋路 ──
					if row_rng.randf() > 0.78:
						_draw_brick_crack(wall_renderer, brick_rect, row_rng)
						
					current_x += bw
				current_y += bh
				
			# ── 牆壁周圍反光與大邊框細化 ──
			# 如果南邊（下方）為地板，說明該牆面朝向玩家，繪製頂蓋高光與底部厚重陰影
			if gen.is_floor(x, y + 1):
				# 頂蓋亮緣線
				wall_renderer.draw_line(world_pos, world_pos + Vector2(TILE_SIZE, 0), COLOR_STONE_HIGHLIGHT, 1.5)
				# 牆角交接暗緣線
				wall_renderer.draw_line(world_pos + Vector2(0, TILE_SIZE - 1.5), world_pos + Vector2(TILE_SIZE, TILE_SIZE - 1.5), COLOR_WALL_BASE, 3.0)
			
			# 其餘交界部分強化立體灰縫
			if gen.is_floor(x + 1, y):
				wall_renderer.draw_line(world_pos + Vector2(TILE_SIZE - 1, 0), world_pos + Vector2(TILE_SIZE - 1, TILE_SIZE), COLOR_WALL_BASE, 2.0)
			if gen.is_floor(x - 1, y):
				wall_renderer.draw_line(world_pos, world_pos + Vector2(0, TILE_SIZE), COLOR_WALL_BASE, 2.0)
			if gen.is_floor(x, y - 1):
				wall_renderer.draw_line(world_pos, world_pos + Vector2(TILE_SIZE, 0), COLOR_WALL_BASE, 2.0)
				
			# ── 牆角立體斑駁青苔 (Moss Layer) ──
			var rng_m = RandomNumberGenerator.new()
			rng_m.seed = x * 7331 + y * 2713
			
			# 如果下方是地板，在牆角繪製疊加圓形的蓬鬆青苔
			if rng_m.randf() > 0.65 and gen.is_floor(x, y + 1):
				var num_moss = rng_m.randi_range(4, 9)
				for m in num_moss:
					var m_radius = rng_m.randf_range(3.0, 7.5)
					var m_x = world_pos.x + rng_m.randf_range(4.0, TILE_SIZE - 4.0)
					var m_y = world_pos.y + TILE_SIZE - rng_m.randf_range(1.0, 8.5)
					
					# 繪製蓬鬆層次：底層深色 shadow，上層亮色 highlight
					wall_renderer.draw_circle(Vector2(m_x, m_y), m_radius, COLOR_MOSS_DARK)
					wall_renderer.draw_circle(Vector2(m_x - 0.6, m_y - 0.6), m_radius * 0.7, COLOR_MOSS_LIGHT)

# ── 石磚微型裂縫輔助函數 ─────────────────────────────
func _draw_brick_crack(renderer: Node2D, rect: Rect2, local_rng: RandomNumberGenerator) -> void:
	var c_x = rect.position.x + local_rng.randf_range(rect.size.x * 0.25, rect.size.x * 0.75)
	var c_y = rect.position.y + local_rng.randf_range(rect.size.y * 0.25, rect.size.y * 0.75)
	var c_len = local_rng.randf_range(5.0, 13.0)
	var c_ang = local_rng.randf() * TAU
	var end_pt = Vector2(c_x + cos(c_ang) * c_len, c_y + sin(c_ang) * c_len)
	
	# 深溝線
	renderer.draw_line(Vector2(c_x, c_y), end_pt, COLOR_CRACK, 1.0)
	# 裂縫受光邊緣 (LIT)
	renderer.draw_line(Vector2(c_x + 0.5, c_y + 0.5), end_pt + Vector2(0.5, 0.5), COLOR_CRACK_LIT, 0.7)


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
