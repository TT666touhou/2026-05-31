# DungeonGenerator.gd
# 網格法 (Grid-Based) 地下城地圖生成器
# 將地圖劃分為 4x3 網格，在每個網格單元格內生成一個房間，並使用最小生成樹 (MST) 及 L 形短走廊進行乾淨的連接。

class_name DungeonGenerator
extends RefCounted

# ── 常數 ───────────────────────────────────────────────
const TILE_FLOOR   = Vector2i(0, 0)  # 地板
const TILE_WALL    = Vector2i(1, 0)  # 牆壁
const TILE_DOOR    = Vector2i(2, 0)  # 門

# ── 資料結構 ────────────────────────────────────────────
class RoomData:
	var rect: Rect2i
	var type: String  # "normal", "elite", "treasure", "boss", "shop", "start"
	var grid_pos: Vector2i
	var center: Vector2i:
		get: return rect.position + Vector2i(rect.size.x >> 1, rect.size.y >> 1)
	
	func _init(r: Rect2i, g_pos: Vector2i, t: String = "normal") -> void:
		rect = r
		grid_pos = g_pos
		type = t

# ── 生成參數 ────────────────────────────────────────────
var map_width:  int = 80   # 地圖總寬（格）
var map_height: int = 60   # 地圖總高（格）
var corridor_width: int = 2   # 走廊寬度（設為 2 方便布娃娃角色通過不卡住）

# ── 輸出資料 ────────────────────────────────────────────
var tile_map: Array = []      # [y][x] = 0 (floor) / 1 (wall) / -1 (empty)
var rooms: Array[RoomData] = []
var corridors: Array[Rect2i] = []
var start_room: RoomData = null
var boss_room: RoomData  = null
var rng: RandomNumberGenerator

# DSU (Disjoint Set Union) 用於 Kruskal 演算法
var _dsu_parent = {}

# ═══════════════════════════════════════════════════════
func _init() -> void:
	rng = RandomNumberGenerator.new()

# ── 主入口 ─────────────────────────────────────────────
func generate(p_seed: int = 0) -> void:
	if p_seed != 0:
		rng.seed = p_seed
	else:
		rng.randomize()
	
	rooms.clear()
	corridors.clear()
	_init_tile_map()
	
	# 1. 劃分 4x3 網格並生成房間
	var cols = 4
	var rows = 3
	var cell_w = map_width / cols   # 20
	var cell_h = map_height / rows  # 20
	
	var grid_rooms = {} # Vector2i -> RoomData
	
	for r in rows:
		for c in cols:
			var grid_coord = Vector2i(c, r)
			
			# 隨機決定是否生成房間（角落或邊緣有 15% 機率不生成以增加地形隨機形狀，但保證起點與終點必有）
			if grid_coord != Vector2i(0, 1) and grid_coord != Vector2i(3, 1):
				if rng.randf() > 0.85:
					continue
			
			# 限制房間尺寸在單元格內，預留邊界
			var min_size = 7
			var max_w = cell_w - 4 # 16
			var max_h = cell_h - 4 # 16
			
			var room_w = rng.randi_range(min_size, max_w)
			var room_h = rng.randi_range(min_size, max_h)
			
			# 隨機擺放在單元格內
			var rx = c * cell_w + rng.randi_range(2, cell_w - room_w - 2)
			var ry = r * cell_h + rng.randi_range(2, cell_h - room_h - 2)
			
			var room_rect = Rect2i(rx, ry, room_w, room_h)
			var rd = RoomData.new(room_rect, grid_coord)
			rooms.append(rd)
			grid_rooms[grid_coord] = rd
	
	# 2. 收集所有相鄰房間的候選連接邊
	var potential_edges = []
	var spawned_coords = grid_rooms.keys()
	
	for i in range(spawned_coords.size()):
		var coord1 = spawned_coords[i]
		for j in range(i + 1, spawned_coords.size()):
			var coord2 = spawned_coords[j]
			var diff = coord2 - coord1
			# 僅考慮網格上水平或垂直相鄰的單元格
			if (abs(diff.x) == 1 and diff.y == 0) or (abs(diff.y) == 1 and diff.x == 0):
				potential_edges.append([coord1, coord2])
				
	# 3. 使用 Kruskal 演算法建立最小生成樹 (MST) 確保全部連通
	_dsu_parent.clear()
	for coord in spawned_coords:
		_dsu_parent[coord] = coord
		
	# 隨機打亂候選邊
	_shuffle_array(potential_edges)
	
	var mst_edges = []
	var unused_edges = []
	
	for edge in potential_edges:
		var u = edge[0]
		var v = edge[1]
		if _dsu_find(u) != _dsu_find(v):
			_dsu_union(u, v)
			mst_edges.append(edge)
		else:
			unused_edges.append(edge)
			
	# 4. 隨機將 25% 的未選用邊加回，形成環狀與捷徑通道，避免地圖過於單一線性
	for edge in unused_edges:
		if rng.randf() < 0.25:
			mst_edges.append(edge)
			
	# 5. 在 tile_map 中雕刻房間
	for rd in rooms:
		for y in range(rd.rect.position.y, rd.rect.position.y + rd.rect.size.y):
			for x in range(rd.rect.position.x, rd.rect.position.x + rd.rect.size.x):
				if y >= 0 and y < map_height and x >= 0 and x < map_width:
					tile_map[y][x] = 0
					
	# 6. 在 tile_map 中雕刻走廊 (L 形短直角走廊)
	for edge in mst_edges:
		var r1 = grid_rooms[edge[0]]
		var r2 = grid_rooms[edge[1]]
		_carve_corridor(r1.center, r2.center)
		
	# 7. 分配房間功能類型
	_assign_room_types(grid_rooms)
	
	# 8. 圍繞可通行格子（地板）產生牆壁
	_add_walls()

# ── 初始化地圖 ──────────────────────────────────────────
func _init_tile_map() -> void:
	tile_map = []
	for y in map_height:
		tile_map.append([])
		for x in map_width:
			tile_map[y].append(-1)  # -1 = 實心空白

# ── DSU 輔助函數 ────────────────────────────────────────
func _dsu_find(v: Vector2i) -> Vector2i:
	if _dsu_parent[v] == v:
		return v
	_dsu_parent[v] = _dsu_find(_dsu_parent[v])
	return _dsu_parent[v]

func _dsu_union(u: Vector2i, v: Vector2i) -> bool:
	var root_u = _dsu_find(u)
	var root_v = _dsu_find(v)
	if root_u != root_v:
		_dsu_parent[root_v] = root_u
		return true
	return false

# ── 打亂陣列 ────────────────────────────────────────────
func _shuffle_array(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp

# ── 雕刻直角 L 形走廊 ───────────────────────────────────
func _carve_corridor(a: Vector2i, b: Vector2i) -> void:
	var hw = corridor_width >> 1
	var remainder = corridor_width % 2
	
	# 先隨機決定是先橫再直，還是先直再橫
	var horizontal_first = rng.randf() > 0.5
	
	if horizontal_first:
		# 水平段 (a.x 到 b.x，高度為 a.y)
		var x_start = min(a.x, b.x)
		var x_end = max(a.x, b.x)
		for x in range(x_start, x_end + 1):
			for dy in range(-hw, hw + remainder):
				var y = a.y + dy
				if y >= 0 and y < map_height and x >= 0 and x < map_width:
					tile_map[y][x] = 0
		# 垂直段 (a.y 到 b.y，寬度為 b.x)
		var y_start = min(a.y, b.y)
		var y_end = max(a.y, b.y)
		for y in range(y_start, y_end + 1):
			for dx in range(-hw, hw + remainder):
				var x = b.x + dx
				if y >= 0 and y < map_height and x >= 0 and x < map_width:
					tile_map[y][x] = 0
		
		corridors.append(Rect2i(x_start, a.y - hw, x_end - x_start + 1, corridor_width))
		corridors.append(Rect2i(b.x - hw, y_start, corridor_width, y_end - y_start + 1))
	else:
		# 垂直段 (a.y 到 b.y，寬度為 a.x)
		var y_start = min(a.y, b.y)
		var y_end = max(a.y, b.y)
		for y in range(y_start, y_end + 1):
			for dx in range(-hw, hw + remainder):
				var x = a.x + dx
				if y >= 0 and y < map_height and x >= 0 and x < map_width:
					tile_map[y][x] = 0
		# 水平段 (a.x 到 b.x，高度為 b.y)
		var x_start = min(a.x, b.x)
		var x_end = max(a.x, b.x)
		for x in range(x_start, x_end + 1):
			for dy in range(-hw, hw + remainder):
				var y = b.y + dy
				if y >= 0 and y < map_height and x >= 0 and x < map_width:
					tile_map[y][x] = 0
		
		corridors.append(Rect2i(a.x - hw, y_start, corridor_width, y_end - y_start + 1))
		corridors.append(Rect2i(x_start, b.y - hw, x_end - x_start + 1, corridor_width))

# ── 分配房間功能類型 ────────────────────────────────────
func _assign_room_types(grid_rooms: Dictionary) -> void:
	if rooms.is_empty():
		return
		
	# 起點必為左中 (0, 1) 的房間，若沒有則選取最左側的房間
	var start_coord = Vector2i(0, 1)
	if grid_rooms.has(start_coord):
		start_room = grid_rooms[start_coord]
	else:
		# 尋找最左邊的房間
		start_room = rooms[0]
		for rd in rooms:
			if rd.rect.position.x < start_room.rect.position.x:
				start_room = rd
	start_room.type = "start"
	
	# 終點（Boss 房）必為右中 (3, 1) 的房間，若沒有則選取最右側的房間
	var boss_coord = Vector2i(3, 1)
	if grid_rooms.has(boss_coord):
		boss_room = grid_rooms[boss_coord]
	else:
		boss_room = rooms[0]
		for rd in rooms:
			if rd.rect.position.x > boss_room.rect.position.x:
				boss_room = rd
	boss_room.type = "boss"
	
	# 中間房間依隨機權重分配類型
	for rd in rooms:
		if rd == start_room or rd == boss_room:
			continue
			
		var col = rd.grid_pos.x
		var roll = rng.randf()
		
		if col == 1:
			if roll < 0.25:
				rd.type = "shop"
			elif roll < 0.45:
				rd.type = "treasure"
			else:
				rd.type = "normal"
		elif col == 2:
			if roll < 0.35:
				rd.type = "elite"
			elif roll < 0.55:
				rd.type = "treasure"
			else:
				rd.type = "normal"
		else:
			if roll < 0.15:
				rd.type = "treasure"
			else:
				rd.type = "normal"

# ── 圍繞地板填牆 ────────────────────────────────────────
func _add_walls() -> void:
	var wall_candidates = []
	for y in map_height:
		for x in map_width:
			if tile_map[y][x] == -1:
				var neighbors = [
					Vector2i(x-1, y), Vector2i(x+1, y),
					Vector2i(x, y-1), Vector2i(x, y+1),
					Vector2i(x-1, y-1), Vector2i(x+1, y-1),
					Vector2i(x-1, y+1), Vector2i(x+1, y+1)
				]
				var has_floor_neighbor = false
				for n in neighbors:
					if n.y >= 0 and n.y < map_height and n.x >= 0 and n.x < map_width:
						if tile_map[n.y][n.x] == 0:
							has_floor_neighbor = true
							break
				if has_floor_neighbor:
					wall_candidates.append(Vector2i(x, y))
					
	for pos in wall_candidates:
		if tile_map[pos.y][pos.x] == -1:
			tile_map[pos.y][pos.x] = 1 # 1 = 牆壁

# ── 外部輔助函數 ────────────────────────────────────────
func get_tile(x: int, y: int) -> int:
	if x < 0 or x >= map_width or y < 0 or y >= map_height:
		return -1
	return tile_map[y][x]

func is_floor(x: int, y: int) -> bool:
	return get_tile(x, y) == 0

func is_wall(x: int, y: int) -> bool:
	return get_tile(x, y) == 1

func tile_to_world(tile_pos: Vector2i, tile_size: int = 64) -> Vector2:
	return Vector2(tile_pos.x * tile_size, tile_pos.y * tile_size)
