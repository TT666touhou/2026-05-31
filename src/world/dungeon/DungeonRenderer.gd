# DungeonRenderer.gd
# 用程序繪製（draw_rect / draw_line）在 Node2D 上直接渲染地下城地圖
# 不依賴任何外部貼圖，與 ProceduralDrawer 的棍人哲學一致

class_name DungeonRenderer
extends Node2D

# ── 繪製常數 ────────────────────────────────────────────
const TILE_SIZE := 64

# 顏色定義（Darkwood 考察：視野外應是脫飽和灰調，非純黑）
# 這些是 PointLight2D 照亮後的「光照內」顏色。光照外 Godot 自動根據 CanvasModulate 暗化。
const COLOR_FLOOR_BASE   := Color(0.40, 0.34, 0.28, 1.0)   # 腐木板底色
const COLOR_FLOOR_VAR1   := Color(0.32, 0.26, 0.20, 1.0)   # 暗褐色腐木板
const COLOR_FLOOR_VAR2   := Color(0.46, 0.40, 0.34, 1.0)   # 稍亮腐木板
const COLOR_WALL_BASE    := Color(0.30, 0.26, 0.22, 1.0)   # 厚石牆底層
const COLOR_WALL_TOP     := Color(0.42, 0.38, 0.34, 1.0)   # 牆壁頂部面
const COLOR_WALL_EDGE    := Color(0.14, 0.12, 0.10, 1.0)   # 牆壁最暗部
const COLOR_CRACK        := Color(0.10, 0.08, 0.07, 0.9)   # 地板裂紋/木紋縫隙
const COLOR_GROUT        := Color(0.16, 0.13, 0.11, 0.8)   # 木板縫隙線
const COLOR_MOSS         := Color(0.22, 0.28, 0.18, 0.50)  # 牆角發霉苔蘚

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
			
			# 用座標決定顏色變體（固定，不每幀重算）
			rng_local.seed = x * 9137 + y * 3517
			var roll = rng_local.randf()
			
			var col: Color
			if roll < 0.60:
				col = COLOR_FLOOR_BASE
			elif roll < 0.80:
				col = COLOR_FLOOR_VAR1
			else:
				col = COLOR_FLOOR_VAR2
			
			# 底色
			draw_rect(Rect2(world_pos, Vector2(TILE_SIZE, TILE_SIZE)), col)
			
			# ── 畫木質地板條紋（4條板，歪斜不整齊的腐木風） ──
			var plank_h = TILE_SIZE / 4.0
			for i in range(1, 4):
				var offset_start = rng_local.randf_range(-1.5, 1.5)
				var offset_end = rng_local.randf_range(-1.5, 1.5)
				draw_line(
					world_pos + Vector2(0, i * plank_h + offset_start),
					world_pos + Vector2(TILE_SIZE, i * plank_h + offset_end),
					COLOR_GROUT, 1.5
				)
			
			# ── 隨機發霉與泥污污漬 ──
			if roll > 0.65:
				var num_spots = rng_local.randi_range(1, 3)
				for s in num_spots:
					var spot_pos = world_pos + Vector2(rng_local.randf_range(8, TILE_SIZE-8), rng_local.randf_range(8, TILE_SIZE-8))
					var spot_rad = rng_local.randf_range(3.0, 9.0)
					draw_circle(spot_pos, spot_rad, Color(0.06, 0.05, 0.04, 0.35))
			
			# 偶發裂縫與木板刮痕
			if roll > 0.90:
				_draw_crack(world_pos, rng_local)

# ── 隨機裂縫細節 ────────────────────────────────────────
func _draw_crack(world_pos: Vector2, local_rng: RandomNumberGenerator) -> void:
	var crack_x = world_pos.x + local_rng.randi_range(10, 54)
	var crack_y = world_pos.y + local_rng.randi_range(10, 54)
	var length  = local_rng.randi_range(8, 22)
	var angle   = local_rng.randf() * TAU
	var end_pt  = Vector2(crack_x + cos(angle) * length, crack_y + sin(angle) * length)
	draw_line(Vector2(crack_x, crack_y), end_pt, COLOR_CRACK, 1.5)

# ── 牆壁與 AO 陰影繪製 ──────────────────────────────────
func _draw_wall_ao() -> void:
	for y in gen.map_height:
		for x in gen.map_width:
			if not gen.is_wall(x, y):
				continue
			
			var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			
			# ── 繪製環境光遮蔽 (AO) 陰影到相鄰地板上 ──
			# 向南鄰接地板
			if gen.is_floor(x, y + 1):
				draw_rect(Rect2(world_pos.x, world_pos.y + TILE_SIZE, TILE_SIZE, 6), Color(0.0, 0.0, 0.0, 0.45))
				draw_rect(Rect2(world_pos.x, world_pos.y + TILE_SIZE + 6, TILE_SIZE, 6), Color(0.0, 0.0, 0.0, 0.30))
				draw_rect(Rect2(world_pos.x, world_pos.y + TILE_SIZE + 12, TILE_SIZE, 6), Color(0.0, 0.0, 0.0, 0.15))
			# 向北鄰接地板
			if gen.is_floor(x, y - 1):
				draw_rect(Rect2(world_pos.x, world_pos.y - 6, TILE_SIZE, 6), Color(0.0, 0.0, 0.0, 0.45))
				draw_rect(Rect2(world_pos.x, world_pos.y - 12, TILE_SIZE, 6), Color(0.0, 0.0, 0.0, 0.30))
				draw_rect(Rect2(world_pos.x, world_pos.y - 18, TILE_SIZE, 6), Color(0.0, 0.0, 0.0, 0.15))
			# 向東鄰接地板
			if gen.is_floor(x + 1, y):
				draw_rect(Rect2(world_pos.x + TILE_SIZE, world_pos.y, 6, TILE_SIZE), Color(0.0, 0.0, 0.0, 0.45))
				draw_rect(Rect2(world_pos.x + TILE_SIZE + 6, world_pos.y, 6, TILE_SIZE), Color(0.0, 0.0, 0.0, 0.30))
				draw_rect(Rect2(world_pos.x + TILE_SIZE + 12, world_pos.y, 6, TILE_SIZE), Color(0.0, 0.0, 0.0, 0.15))
			# 向西鄰接地板
			if gen.is_floor(x - 1, y):
				draw_rect(Rect2(world_pos.x - 6, world_pos.y, 6, TILE_SIZE), Color(0.0, 0.0, 0.0, 0.45))
				draw_rect(Rect2(world_pos.x - 12, world_pos.y, 6, TILE_SIZE), Color(0.0, 0.0, 0.0, 0.30))
				draw_rect(Rect2(world_pos.x - 18, world_pos.y, 6, TILE_SIZE), Color(0.0, 0.0, 0.0, 0.15))

func _draw_walls_layer() -> void:
	if gen == null or not wall_renderer:
		return
		
	for y in gen.map_height:
		for x in gen.map_width:
			if not gen.is_wall(x, y):
				continue
				
			var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			
			# ── 牆壁本體底色 ──
			wall_renderer.draw_rect(Rect2(world_pos, Vector2(TILE_SIZE, TILE_SIZE)), COLOR_WALL_BASE)
			
			# 畫牆面磚石紋路
			var wall_rng = RandomNumberGenerator.new()
			wall_rng.seed = x * 8461 + y * 9733
			
			# 畫水平分割縫 (分成 3 層石磚)
			var brick_h = TILE_SIZE / 3.0
			for i in range(1, 3):
				var h_y = world_pos.y + i * brick_h
				wall_renderer.draw_line(Vector2(world_pos.x, h_y), Vector2(world_pos.x + TILE_SIZE, h_y), COLOR_WALL_EDGE, 1.0)
				
			# 畫垂直磚縫
			for i in range(3):
				var h_y = world_pos.y + i * brick_h
				var v_offset = wall_rng.randi_range(12, TILE_SIZE - 12)
				wall_renderer.draw_line(Vector2(world_pos.x + v_offset, h_y), Vector2(world_pos.x + v_offset, h_y + brick_h), COLOR_WALL_EDGE, 1.0)
				
			# 偶爾畫牆壁裂紋
			if wall_rng.randf() > 0.85:
				var c_x = world_pos.x + wall_rng.randi_range(10, 54)
				var c_y = world_pos.y + wall_rng.randi_range(10, 54)
				var c_len = wall_rng.randi_range(8, 20)
				var c_ang = wall_rng.randf() * TAU
				var c_end = Vector2(c_x + cos(c_ang) * c_len, c_y + sin(c_ang) * c_len)
				wall_renderer.draw_line(Vector2(c_x, c_y), c_end, COLOR_WALL_EDGE, 1.2)
			
			# 牆壁頂面（面向玩家的「蓋子」，稍微粗糙點綴）
			if gen.is_floor(x, y + 1):
				# 下邊鄰接地板：畫亮部頂面
				wall_renderer.draw_rect(Rect2(world_pos, Vector2(TILE_SIZE, 6)), COLOR_WALL_TOP)
				# 牆體陰影邊緣
				wall_renderer.draw_rect(Rect2(world_pos + Vector2(0, TILE_SIZE - 4), Vector2(TILE_SIZE, 4)), COLOR_WALL_EDGE)
			if gen.is_floor(x + 1, y):
				wall_renderer.draw_rect(Rect2(world_pos + Vector2(TILE_SIZE - 3, 0), Vector2(3, TILE_SIZE)), COLOR_WALL_EDGE)
			if gen.is_floor(x - 1, y):
				wall_renderer.draw_rect(Rect2(world_pos, Vector2(3, TILE_SIZE)), COLOR_WALL_EDGE)
				
			# 偶爾在牆壁底部畫青苔/發霉
			var rng_m = RandomNumberGenerator.new()
			rng_m.seed = x * 7331 + y * 2713
			if rng_m.randf() > 0.75 and gen.is_floor(x, y + 1):
				var moss_w = rng_m.randi_range(8, 32)
				var moss_x = rng_m.randi_range(0, TILE_SIZE - moss_w)
				wall_renderer.draw_rect(Rect2(world_pos + Vector2(moss_x, TILE_SIZE - 8), Vector2(moss_w, 4)), COLOR_MOSS)

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
