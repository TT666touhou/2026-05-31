# DungeonRenderer.gd
# 用程序繪製（draw_rect / draw_line）在 Node2D 上直接渲染地下城地圖
# 不依賴任何外部貼圖，與 ProceduralDrawer 的棍人哲學一致

class_name DungeonRenderer
extends Node2D

# ── 繪製常數 ────────────────────────────────────────────
const TILE_SIZE := 64

# 顏色定義（參考考察文件的 Darkwood 色調）
const COLOR_FLOOR_BASE   := Color(0.16, 0.14, 0.12, 1.0)   # 深棕灰地板
const COLOR_FLOOR_VAR1   := Color(0.14, 0.12, 0.10, 1.0)   # 地板變體1（稍暗）
const COLOR_FLOOR_VAR2   := Color(0.18, 0.16, 0.14, 1.0)   # 地板變體2（稍亮）
const COLOR_WALL_TOP     := Color(0.11, 0.10, 0.09, 1.0)   # 牆壁頂部（稍亮，體積感）
const COLOR_WALL_SIDE    := Color(0.05, 0.04, 0.03, 1.0)   # 牆壁側面（深色，厚度感）
const COLOR_CRACK        := Color(0.05, 0.04, 0.03, 0.6)   # 裂縫線
const COLOR_GROUT        := Color(0.06, 0.05, 0.05, 1.0)   # 地板縫隙（石材接縫）
const COLOR_AO_1         := Color(0.0, 0.0, 0.0, 0.35)     # 環境光遮蔽（近）
const COLOR_AO_2         := Color(0.0, 0.0, 0.0, 0.15)     # 環境光遮蔽（遠）

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

# ── 入口 ────────────────────────────────────────────────
func render(generator: DungeonGenerator) -> void:
	gen = generator
	_clear_walls()
	_build_wall_colliders()
	queue_redraw()

func _clear_walls() -> void:
	for body in wall_bodies:
		if is_instance_valid(body):
			body.queue_free()
	wall_bodies.clear()

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

# ── 建立光影遮擋體 (Occluders) 給 MaskViewport 用 ─────────
func build_occluders(parent_node: Node) -> void:
	if gen == null:
		return
	
	for y in gen.map_height:
		var start_x: int = -1
		for x in range(gen.map_width + 1):
			var is_w = x < gen.map_width and gen.is_wall(x, y)
			if is_w and start_x == -1:
				start_x = x
			elif not is_w and start_x != -1:
				var w = x - start_x
				var occ = LightOccluder2D.new()
				var poly = OccluderPolygon2D.new()
				
				# 建立符合牆壁大小的矩形多邊形
				var pts = PackedVector2Array([
					Vector2(0, 0),
					Vector2(w * TILE_SIZE, 0),
					Vector2(w * TILE_SIZE, TILE_SIZE),
					Vector2(0, TILE_SIZE)
				])
				poly.polygon = pts
				poly.closed = true
				occ.occluder = poly
				occ.position = Vector2(start_x * TILE_SIZE, y * TILE_SIZE)
				parent_node.add_child(occ)
				
				start_x = -1

# ── _draw 主繪製 ────────────────────────────────────────
func _draw() -> void:
	if gen == null:
		return
	
	_draw_floors()
	_draw_walls()
	
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
			
			# 石材接縫線（每格右邊和下邊）
			draw_line(
				world_pos + Vector2(TILE_SIZE - 1, 0),
				world_pos + Vector2(TILE_SIZE - 1, TILE_SIZE),
				COLOR_GROUT, 1.0
			)
			draw_line(
				world_pos + Vector2(0, TILE_SIZE - 1),
				world_pos + Vector2(TILE_SIZE, TILE_SIZE - 1),
				COLOR_GROUT, 1.0
			)
			
			# 偶發裂縫（約 8% 的格子有）
			if roll > 0.92:
				_draw_crack(world_pos, rng_local)

# ── 隨機裂縫細節 ────────────────────────────────────────
func _draw_crack(world_pos: Vector2, local_rng: RandomNumberGenerator) -> void:
	var crack_x = world_pos.x + local_rng.randi_range(10, 54)
	var crack_y = world_pos.y + local_rng.randi_range(10, 54)
	var length  = local_rng.randi_range(6, 18)
	var angle   = local_rng.randf() * TAU
	var end_pt  = Vector2(crack_x + cos(angle) * length, crack_y + sin(angle) * length)
	draw_line(Vector2(crack_x, crack_y), end_pt, COLOR_CRACK, 1.0)

# ── 牆壁繪製與 AO ─────────────────────────────────────────
func _draw_walls() -> void:
	for y in gen.map_height:
		for x in gen.map_width:
			if not gen.is_wall(x, y):
				continue
			
			var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			
			# 牆壁頂部 (立體感)
			draw_rect(Rect2(world_pos, Vector2(TILE_SIZE, TILE_SIZE - 12)), COLOR_WALL_TOP)
			
			# 牆壁側面 (厚度感，下方)
			draw_rect(Rect2(world_pos + Vector2(0, TILE_SIZE - 12), Vector2(TILE_SIZE, 12)), COLOR_WALL_SIDE)
			
			# ── 環境光遮蔽 (AO) ──
			# 如果下方是地板，在地板上畫漸層 AO
			if gen.is_floor(x, y + 1):
				var ao_pos = world_pos + Vector2(0, TILE_SIZE)
				draw_rect(Rect2(ao_pos, Vector2(TILE_SIZE, 6)), COLOR_AO_1)
				draw_rect(Rect2(ao_pos + Vector2(0, 6), Vector2(TILE_SIZE, 6)), COLOR_AO_2)
			
			# 如果上方是地板，在地板上畫漸層 AO
			if gen.is_floor(x, y - 1):
				var ao_pos = world_pos - Vector2(0, 12)
				draw_rect(Rect2(ao_pos + Vector2(0, 6), Vector2(TILE_SIZE, 6)), COLOR_AO_1)
				draw_rect(Rect2(ao_pos, Vector2(TILE_SIZE, 6)), COLOR_AO_2)
			
			# 如果右方是地板
			if gen.is_floor(x + 1, y):
				var ao_pos = world_pos + Vector2(TILE_SIZE, 0)
				draw_rect(Rect2(ao_pos, Vector2(6, TILE_SIZE)), COLOR_AO_1)
				draw_rect(Rect2(ao_pos + Vector2(6, 0), Vector2(6, TILE_SIZE)), COLOR_AO_2)
				
			# 如果左方是地板
			if gen.is_floor(x - 1, y):
				var ao_pos = world_pos - Vector2(12, 0)
				draw_rect(Rect2(ao_pos + Vector2(6, 0), Vector2(6, TILE_SIZE)), COLOR_AO_1)
				draw_rect(Rect2(ao_pos, Vector2(6, TILE_SIZE)), COLOR_AO_2)

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
