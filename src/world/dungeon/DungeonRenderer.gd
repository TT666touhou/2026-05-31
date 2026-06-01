# DungeonRenderer.gd
# 向量扁平線條風 (Flat Vector Line-Art) 地下城地圖渲染器
# 專為契合玩家 (Player) 與殭屍 (Zombie) 的火柴人 (Stickman) 粗線條物理骨架風格進行考據與設計。
# 捨棄細緻貼圖與立體漸變，改用純色填充與粗黑邊框，達成完美的視覺風格統一。

class_name DungeonRenderer
extends Node2D

# ── 繪製常數 ────────────────────────────────────────────
const TILE_SIZE := 64

# 風格化配色（Darkwood 考察：低飽和、陰鬱的褐色與灰色調，襯托出白色線條人）
const COLOR_FLOOR_BASE   := Color(0.24, 0.20, 0.17, 1.0)   # 基礎地板純色
const COLOR_FLOOR_VAR1   := Color(0.21, 0.18, 0.15, 1.0)   # 暗色地板
const COLOR_FLOOR_VAR2   := Color(0.27, 0.23, 0.19, 1.0)   # 亮色地板
const COLOR_GROUT        := Color(0.12, 0.10, 0.08, 1.0)   # 木板拼接的粗邊框線 (等同角色描邊)

const COLOR_WALL_BASE    := Color(0.16, 0.14, 0.12, 1.0)   # 牆壁填充底色
const COLOR_WALL_SHADOW  := Color(0.08, 0.07, 0.06, 1.0)   # 牆面縫隙與外部描邊色 (粗黑線)
const COLOR_WALL_TOP_LINE:= Color(0.28, 0.25, 0.22, 1.0)   # 牆面受光部的向量亮邊

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
	wall_renderer.light_mask = 8 # Layer 4 (牆頂受光亮部遮罩)
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

# ── 地板繪製（粗線條拼接木板 - 無漸層與多餘細節）───────
func _draw_floors() -> void:
	var rng_local = RandomNumberGenerator.new()
	
	for y in gen.map_height:
		for x in gen.map_width:
			if not gen.is_floor(x, y):
				continue
			
			var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			
			rng_local.seed = x * 8831 + y * 4909
			var roll = rng_local.randf()
			
			# 決定地板底色（純色變體，維持簡約）
			var col: Color
			if roll < 0.60:
				col = COLOR_FLOOR_BASE
			elif roll < 0.85:
				col = COLOR_FLOOR_VAR1
			else:
				col = COLOR_FLOOR_VAR2
			
			# 1. 繪製純色地板底色
			draw_rect(Rect2(world_pos, Vector2(TILE_SIZE, TILE_SIZE)), col)
			
			# 2. 繪製極簡粗木板間隔線 (對齊火柴人邊線寬度：3px)
			var plank_h = TILE_SIZE / 3.0
			for i in range(1, 3):
				var py = world_pos.y + i * plank_h
				draw_line(
					Vector2(world_pos.x, py),
					Vector2(world_pos.x + TILE_SIZE, py),
					COLOR_GROUT,
					3.0
				)
				
			# 3. 繪製地板外框（粗邊框線），建立清爽的格線感
			draw_rect(Rect2(world_pos, Vector2(TILE_SIZE, TILE_SIZE)), COLOR_GROUT, false, 3.0)

# ── 牆壁環境陰影 (風格化單色黑色半透明邊帶) ─────────────
# 拋棄漸層，改用均一的不透明度黑色邊帶，展現簡約漫畫/向量風格的陰影
func _draw_wall_ao() -> void:
	var shadow_w: float = 16.0 # 陰影厚度
	var shadow_color = Color(0, 0, 0, 0.35)
	
	for y in gen.map_height:
		for x in gen.map_width:
			if not gen.is_wall(x, y):
				continue
				
			var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			
			# 向南鄰接地表
			if gen.is_floor(x, y + 1):
				draw_rect(Rect2(world_pos.x, world_pos.y + TILE_SIZE, TILE_SIZE, shadow_w), shadow_color)
			# 向北鄰接地表
			if gen.is_floor(x, y - 1):
				draw_rect(Rect2(world_pos.x, world_pos.y - shadow_w, TILE_SIZE, shadow_w), shadow_color)
			# 向東鄰接地表
			if gen.is_floor(x + 1, y):
				draw_rect(Rect2(world_pos.x + TILE_SIZE, world_pos.y, shadow_w, TILE_SIZE), shadow_color)
			# 向西鄰接地表
			if gen.is_floor(x - 1, y):
				draw_rect(Rect2(world_pos.x - shadow_w, world_pos.y, shadow_w, TILE_SIZE), shadow_color)

# ── 牆壁繪製（火柴人粗描邊向量磚牆）───────────────────
# 使用與火柴人手臂完全一致的 4.0 粗描邊，並僅以極簡直線切割出大塊磚塊
func _draw_walls_layer() -> void:
	if gen == null or not wall_renderer:
		return
		
	var border_width = 4.0 # 與火柴人描邊一致的寬度
	
	for y in gen.map_height:
		for x in gen.map_width:
			if not gen.is_wall(x, y):
				continue
				
			var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			
			# 1. 填滿牆面純底色 (向量平塗風)
			wall_renderer.draw_rect(Rect2(world_pos, Vector2(TILE_SIZE, TILE_SIZE)), COLOR_WALL_BASE)
			
			# 2. 繪製牆面外框 (粗描邊)
			wall_renderer.draw_rect(Rect2(world_pos, Vector2(TILE_SIZE, TILE_SIZE)), COLOR_WALL_SHADOW, false, border_width)
			
			# 3. 極簡磚縫線：水平分割線 (將牆面切為上下兩半)
			var mid_y = world_pos.y + TILE_SIZE / 2.0
			wall_renderer.draw_line(
				Vector2(world_pos.x, mid_y),
				Vector2(world_pos.x + TILE_SIZE, mid_y),
				COLOR_WALL_SHADOW,
				border_width
			)
			
			# 垂直磚縫線 (上下交錯擺放，構成磚砌外觀)
			var mid_x = world_pos.x + TILE_SIZE / 2.0
			# 上半段垂直磚縫
			wall_renderer.draw_line(
				Vector2(mid_x, world_pos.y),
				Vector2(mid_x, mid_y),
				COLOR_WALL_SHADOW,
				border_width
			)
			# 下半段垂直磚縫 (擺在 1/4 與 3/4 處，使線條交錯)
			var quarter_x = world_pos.x + TILE_SIZE / 4.0
			var three_quarter_x = world_pos.x + 3.0 * TILE_SIZE / 4.0
			wall_renderer.draw_line(
				Vector2(quarter_x, mid_y),
				Vector2(quarter_x, world_pos.y + TILE_SIZE),
				COLOR_WALL_SHADOW,
				border_width
			)
			wall_renderer.draw_line(
				Vector2(three_quarter_x, mid_y),
				Vector2(three_quarter_x, world_pos.y + TILE_SIZE),
				COLOR_WALL_SHADOW,
				border_width
			)
			
			# 4. 向量邊緣亮邊 (在面向地表的可見邊緣畫上極簡亮色線，增加層次感)
			if gen.is_floor(x, y + 1):
				# 下邊是地板：頂部畫一條亮線 (代表受光牆面頂端)
				wall_renderer.draw_line(
					Vector2(world_pos.x + 2, world_pos.y + 2),
					Vector2(world_pos.x + TILE_SIZE - 2, world_pos.y + 2),
					COLOR_WALL_TOP_LINE,
					2.0
				)

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
