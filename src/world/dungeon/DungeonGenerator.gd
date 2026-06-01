# DungeonGenerator.gd
# BSP (Binary Space Partitioning) 地下城地圖生成器
# 使用 BSP 遞迴切割空間生成房間，並用走廊連接

class_name DungeonGenerator
extends RefCounted

# ── 常數 ───────────────────────────────────────────────
const TILE_FLOOR   = Vector2i(0, 0)  # TileSet Atlas 座標：地板
const TILE_WALL    = Vector2i(1, 0)  # TileSet Atlas 座標：牆壁
const TILE_DOOR    = Vector2i(2, 0)  # TileSet Atlas 座標：門

# ── 資料結構 ────────────────────────────────────────────
class BSPNode:
	var rect: Rect2i          # 此節點代表的地圖區域
	var left: BSPNode         # 左子節點
	var right: BSPNode        # 右子節點
	var room: Rect2i          # 最終生成的房間（只在葉節點有效）
	var is_leaf: bool:
		get: return left == null and right == null
	
	func _init(r: Rect2i) -> void:
		rect = r

class RoomData:
	var rect: Rect2i
	var type: String  # "normal", "elite", "treasure", "boss", "shop", "start"
	var center: Vector2i:
		get: return rect.position + Vector2i(rect.size.x >> 1, rect.size.y >> 1)
	
	func _init(r: Rect2i, t: String = "normal") -> void:
		rect = r
		type = t

# ── 生成參數 ────────────────────────────────────────────
var map_width:  int = 80   # 地圖總寬（格）
var map_height: int = 60   # 地圖總高（格）
var min_room_size: int = 5    # 房間最小尺寸（格）
var max_room_size: int = 8    # 房間最大尺寸（格）
var min_split_size: int = 8   # BSP 節點最小可切割尺寸
var corridor_width: int = 1   # 走廊寬度（格）

# ── 輸出資料 ────────────────────────────────────────────
var tile_map: Array = []      # [y][x] = TILE_FLOOR / TILE_WALL / -1
var rooms: Array[RoomData] = []
var corridors: Array[Rect2i] = []
var start_room: RoomData = null
var boss_room: RoomData  = null
var rng: RandomNumberGenerator

# ═══════════════════════════════════════════════════════
func _init() -> void:
	rng = RandomNumberGenerator.new()

# ── 主入口 ─────────────────────────────────────────────
func generate(p_seed: int = 0) -> void:
	if p_seed != 0:
		rng.seed = p_seed
	else:
		rng.randomize()
	
	_init_tile_map()
	
	var root_rect = Rect2i(0, 0, map_width, map_height)
	var root = BSPNode.new(root_rect)
	
	_split(root, 0)
	_collect_rooms(root)
	_connect_rooms(root)
	_carve_to_tile_map()
	_assign_room_types()
	_add_walls()

# ── 初始化地圖陣列（全填牆）──────────────────────────────
func _init_tile_map() -> void:
	tile_map = []
	for y in map_height:
		tile_map.append([])
		for x in map_width:
			tile_map[y].append(-1)  # -1 = 未開鑿（實心牆）

# ── BSP 遞迴切割 ────────────────────────────────────────
func _split(node: BSPNode, depth: int) -> void:
	if depth > 6:
		return
	
	var can_split_h = node.rect.size.y >= min_split_size * 2
	var can_split_v = node.rect.size.x >= min_split_size * 2
	
	if not can_split_h and not can_split_v:
		return
	
	# 根據長寬比決定切割方向（傾向切割較長邊）
	var split_horizontal: bool
	if can_split_h and can_split_v:
		# 如果較寬，偏向垂直切割（反之亦然）
		var ratio = float(node.rect.size.x) / float(node.rect.size.y)
		if ratio > 1.3:
			split_horizontal = false
		elif ratio < 0.77:
			split_horizontal = true
		else:
			split_horizontal = rng.randi_range(0, 1) == 0
	elif can_split_h:
		split_horizontal = true
	else:
		split_horizontal = false
	
	if split_horizontal:
		# 水平切割（分出上下）
		var split_y = rng.randi_range(
			node.rect.position.y + min_split_size,
			node.rect.position.y + node.rect.size.y - min_split_size
		)
		node.left  = BSPNode.new(Rect2i(
			node.rect.position.x, node.rect.position.y,
			node.rect.size.x, split_y - node.rect.position.y
		))
		node.right = BSPNode.new(Rect2i(
			node.rect.position.x, split_y,
			node.rect.size.x, node.rect.position.y + node.rect.size.y - split_y
		))
	else:
		# 垂直切割（分出左右）
		var split_x = rng.randi_range(
			node.rect.position.x + min_split_size,
			node.rect.position.x + node.rect.size.x - min_split_size
		)
		node.left  = BSPNode.new(Rect2i(
			node.rect.position.x, node.rect.position.y,
			split_x - node.rect.position.x, node.rect.size.y
		))
		node.right = BSPNode.new(Rect2i(
			split_x, node.rect.position.y,
			node.rect.position.x + node.rect.size.x - split_x, node.rect.size.y
		))
	
	_split(node.left,  depth + 1)
	_split(node.right, depth + 1)

# ── 在葉節點中生成房間 ──────────────────────────────────
func _collect_rooms(node: BSPNode) -> void:
	if node.is_leaf:
		# 在節點的 rect 內，以隨機偏移生成房間
		var room_w = rng.randi_range(min_room_size, min(max_room_size, node.rect.size.x - 2))
		var room_h = rng.randi_range(min_room_size, min(max_room_size, node.rect.size.y - 2))
		var room_x = node.rect.position.x + rng.randi_range(1, node.rect.size.x - room_w - 1)
		var room_y = node.rect.position.y + rng.randi_range(1, node.rect.size.y - room_h - 1)
		
		node.room = Rect2i(room_x, room_y, room_w, room_h)
		var rd = RoomData.new(node.room)
		rooms.append(rd)
	else:
		if node.left:
			_collect_rooms(node.left)
		if node.right:
			_collect_rooms(node.right)

# ── 用走廊連接兩個 BSP 節點 ─────────────────────────────
func _connect_rooms(node: BSPNode) -> void:
	if node.is_leaf:
		return
	
	_connect_rooms(node.left)
	_connect_rooms(node.right)
	
	# 取兩子節點的代表房間中心，連一條走廊
	var left_center  = _get_room_center(node.left)
	var right_center = _get_room_center(node.right)
	
	_carve_corridor(left_center, right_center)

func _get_room_center(node: BSPNode) -> Vector2i:
	if node.is_leaf:
		return node.room.position + Vector2i(node.room.size.x >> 1, node.room.size.y >> 1)
	elif node.left:
		return _get_room_center(node.left)
	else:
		return _get_room_center(node.right)

# ── 挖走廊（L 形） ──────────────────────────────────────
func _carve_corridor(a: Vector2i, b: Vector2i) -> void:
	var hw = corridor_width >> 1  # 走廊半寬
	
	# 水平段（從 a.x 到 b.x，保持 a.y）
	var x_min = min(a.x, b.x)
	var x_max = max(a.x, b.x)
	for x in range(x_min, x_max + 1):
		for dy in range(-hw, hw + 1):
			var y = a.y + dy
			if y >= 0 and y < map_height and x >= 0 and x < map_width:
				tile_map[y][x] = 0  # 地板
	
	# 垂直段（從 a.y 到 b.y，保持 b.x）
	var y_min = min(a.y, b.y)
	var y_max = max(a.y, b.y)
	for y in range(y_min, y_max + 1):
		for dx in range(-hw, hw + 1):
			var x = b.x + dx
			if x >= 0 and x < map_width and y >= 0 and y < map_height:
				tile_map[y][x] = 0  # 地板
	
	# 記錄走廊 Rect
	corridors.append(Rect2i(x_min - hw, a.y - hw, x_max - x_min + corridor_width, corridor_width))
	corridors.append(Rect2i(b.x - hw, y_min - hw, corridor_width, y_max - y_min + corridor_width))

# ── 把房間 Rect 寫入 tile_map ───────────────────────────
func _carve_to_tile_map() -> void:
	for rd in rooms:
		for y in range(rd.rect.position.y, rd.rect.position.y + rd.rect.size.y):
			for x in range(rd.rect.position.x, rd.rect.position.x + rd.rect.size.x):
				if y >= 0 and y < map_height and x >= 0 and x < map_width:
					tile_map[y][x] = 0  # 0 = 地板

# ── 分配房間類型 ────────────────────────────────────────
func _assign_room_types() -> void:
	if rooms.is_empty():
		return
	
	# 第一個房間 = 出生點
	start_room = rooms[0]
	start_room.type = "start"
	
	# 最後一個房間 = Boss 房間
	boss_room = rooms[rooms.size() - 1]
	boss_room.type = "boss"
	
	# 中間房間依比例分配
	for i in range(1, rooms.size() - 1):
		var roll = rng.randf()
		if roll < 0.10:
			rooms[i].type = "treasure"
		elif roll < 0.16:
			rooms[i].type = "shop"
		elif roll < 0.26:
			rooms[i].type = "elite"
		else:
			rooms[i].type = "normal"

# ── 在所有可通行格子周圍填牆 ────────────────────────────
func _add_walls() -> void:
	# 先收集所有需要變牆的位置
	var wall_candidates: Array[Vector2i] = []
	for y in map_height:
		for x in map_width:
			if tile_map[y][x] == -1:
				# 如果相鄰有地板，這個格子應該變成牆
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var ny = y + dy
						var nx = x + dx
						if ny >= 0 and ny < map_height and nx >= 0 and nx < map_width:
							if tile_map[ny][nx] == 0:
								wall_candidates.append(Vector2i(x, y))
	
	for pos in wall_candidates:
		if tile_map[pos.y][pos.x] == -1:
			tile_map[pos.y][pos.x] = 1  # 1 = 牆壁

# ── 輔助：取格子類型 ────────────────────────────────────
func get_tile(x: int, y: int) -> int:
	if x < 0 or x >= map_width or y < 0 or y >= map_height:
		return -1
	return tile_map[y][x]

func is_floor(x: int, y: int) -> bool:
	return get_tile(x, y) == 0

func is_wall(x: int, y: int) -> bool:
	return get_tile(x, y) == 1

# ── 輔助：取世界座標（格子 → 像素）─────────────────────
func tile_to_world(tile_pos: Vector2i, tile_size: int = 64) -> Vector2:
	return Vector2(tile_pos.x * tile_size, tile_pos.y * tile_size)
