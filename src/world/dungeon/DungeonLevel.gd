# DungeonLevel.gd
# 地下城主場景控制器
# 負責：生成地圖 → 渲染 → 放置玩家 → 放置敵人 → 管理 FOV → 敵人視野隱形

extends Node2D

# ── 節點引用 ────────────────────────────────────────────
@onready var dungeon_renderer : DungeonRenderer = $DungeonRenderer
@onready var entities_layer   : Node2D           = $EntitiesLayer
@onready var canvas_modulate  : CanvasModulate   = $CanvasModulate
@onready var camera           : Camera2D         = $Camera

# 場景 preload
const PLAYER_SCENE  = preload("res://src/entities/player/Player.tscn")
const ZOMBIE_SCENE  = preload("res://src/entities/zombie/Zombie.tscn")
const DUMMY_SCENE   = preload("res://src/entities/dummy/Dummy.tscn")
const FURNITURE_SCENE = preload("res://src/entities/props/PropFurniture.tscn")

# ── 設定 ────────────────────────────────────────────────
@export var map_seed       : int   = 0          # 0 = 隨機
@export var map_width      : int   = 80
@export var map_height     : int   = 60
@export var tile_size      : int   = 64
@export var zombie_per_room: int   = 2
@export var show_debug     : bool  = false

## 視野錐半徑（像素）
@export var vision_radius  : float = 320.0
## 視野錐開口角度（度）
@export var vision_cone_angle: float = 105.0

# ── 狀態 ────────────────────────────────────────────────
var gen: DungeonGenerator
var player_instance: CharacterBody2D
var player_fov: PlayerFOV
var current_floor: int = 1

# 敵人與家具列表（用於每幀視野更新）
var enemy_instances: Array[CharacterBody2D] = []
var prop_instances: Array[RigidBody2D] = []

# ── 生命週期 ────────────────────────────────────────────
func _ready() -> void:
	generate_floor()

func _process(delta: float) -> void:
	_update_camera_look_ahead(delta)

func _unhandled_input(event: InputEvent) -> void:
	# DEBUG：按 R 重新生成地圖
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_clear_entities()
		generate_floor()

# ── 地圖生成主流程 ──────────────────────────────────────
func generate_floor(seed: int = map_seed) -> void:
	# 1. 生成地圖數據
	gen = DungeonGenerator.new()
	gen.map_width   = map_width
	gen.map_height  = map_height
	gen.generate(seed)
	
	# 2. 渲染地圖（程序繪製 + LightOccluder2D）
	dungeon_renderer.show_debug_rooms = show_debug
	dungeon_renderer.render(gen)
	
	# 2.5. 建立尋路網格 (Navigation Mesh)
	_setup_navigation()
	
	# 3. 放置玩家
	_spawn_player()
	
	# 4. 放置敵人
	_spawn_enemies()
	
	# 4.5. 放置家具
	_spawn_furniture()
	
	# 5. 相機設定
	_setup_camera()

# ── 放置玩家在起始房間中心 ─────────────────────────────
func _spawn_player() -> void:
	if player_instance and is_instance_valid(player_instance):
		player_instance.queue_free()
	player_fov = null
	
	var start = gen.start_room
	if start == null and gen.rooms.size() > 0:
		start = gen.rooms[0]
	
	if start == null:
		push_error("DungeonLevel: No start room found!")
		return
	
	player_instance = PLAYER_SCENE.instantiate() as CharacterBody2D
	entities_layer.add_child(player_instance)
	player_instance.position = _room_center_world(start)
	
	# 找 PlayerFOV 並設定視野參數
	player_fov = player_instance.get_node_or_null("VisionLight") as PlayerFOV
	if player_fov:
		player_fov.view_radius  = vision_radius
		player_fov.cone_angle   = vision_cone_angle
		player_fov.follow_mouse = true
	
	# 相機跟隨玩家
	if camera:
		camera.reparent(player_instance)
		camera.position = Vector2.ZERO

# ── 放置敵人 ────────────────────────────────────────────
func _spawn_enemies() -> void:
	enemy_instances.clear()
	
	for rd in gen.rooms:
		if rd.type == "start":
			continue
		
		var count: int
		match rd.type:
			"normal":   count = zombie_per_room
			"elite":    count = 1
			"boss":     count = 1
			"treasure": count = 0
			"shop":     count = 0
			_:          count = zombie_per_room
		
		for i in count:
			_spawn_zombie_in_room(rd)

func _spawn_zombie_in_room(rd: DungeonGenerator.RoomData) -> void:
	var zombie = ZOMBIE_SCENE.instantiate() as CharacterBody2D
	entities_layer.add_child(zombie)
	
	# 在房間內隨機位置（留1格邊距）
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var margin = tile_size
	var rx = rd.rect.position.x * tile_size + margin + rng.randf_range(0, (rd.rect.size.x - 2) * tile_size - margin)
	var ry = rd.rect.position.y * tile_size + margin + rng.randf_range(0, (rd.rect.size.y - 2) * tile_size - margin)
	zombie.position = Vector2(rx, ry)
	enemy_instances.append(zombie)

# ── 清除所有實體 ────────────────────────────────────────
func _clear_entities() -> void:
	for child in entities_layer.get_children():
		child.queue_free()
	player_instance = null
	player_fov      = null
	enemy_instances.clear()
	prop_instances.clear()
	
	var nav = get_node_or_null("NavigationRegion2D")
	if nav:
		nav.queue_free()


# ── 相機設定 ────────────────────────────────────────────
func _setup_camera() -> void:
	if camera == null:
		return
	
	var map_world_w = gen.map_width  * tile_size
	var map_world_h = gen.map_height * tile_size
	
	camera.limit_left   = 0
	camera.limit_top    = 0
	camera.limit_right  = map_world_w
	camera.limit_bottom = map_world_h

# ── 輔助：房間中心世界座標 ──────────────────────────────
func _room_center_world(rd: DungeonGenerator.RoomData) -> Vector2:
	return Vector2(
		(rd.rect.position.x + rd.rect.size.x / 2.0) * tile_size,
		(rd.rect.position.y + rd.rect.size.y / 2.0) * tile_size
	)

# ── 照相機滑鼠拉伸偏移 (Look-Ahead) ──────────────────────
func _update_camera_look_ahead(delta: float) -> void:
	if player_instance == null or not is_instance_valid(player_instance):
		return
	if camera == null or not is_instance_valid(camera):
		return
		
	# 取得滑鼠與玩家之間的向量
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - player_instance.global_position
	
	# 設定最大偏移距離（例如 100 像素，在 2.2x 縮放下很合適）
	var max_offset = 120.0
	var target_offset = to_mouse.limit_length(max_offset) * 0.45 # 讓視角往滑鼠方向偏移
	
	# 平滑插值相機位置
	camera.position = camera.position.lerp(target_offset, delta * 4.0)

# ── 放置家具 ────────────────────────────────────────────
func _spawn_furniture() -> void:
	for rd in gen.rooms:
		# 每個房間隨機生成 1-3 個家具
		var num_furniture = randi_range(1, 3)
		if rd.type == "start":
			# 出生房間放 1 個箱子給玩家測試
			num_furniture = 1
			
		for i in num_furniture:
			var prop = FURNITURE_SCENE.instantiate() as PropFurniture
			entities_layer.add_child(prop)
			
			# 決定家具類型與尺寸
			var roll = randf()
			var p_type: PropFurniture.PropType
			var p_size: Vector2
			
			if roll < 0.40:
				p_type = PropFurniture.PropType.CRATE
				p_size = Vector2(40, 40)
			elif roll < 0.75:
				p_type = PropFurniture.PropType.TABLE
				p_size = Vector2(56, 36)
			else:
				p_type = PropFurniture.PropType.WARDROBE
				p_size = Vector2(64, 28)
				
			prop.setup(p_type, p_size)
			
			# 擺在房間隨機位置（留 1.5 格邊距防穿牆）
			var margin = tile_size * 1.5
			var rx = rd.rect.position.x * tile_size + margin + randf() * ((rd.rect.size.x - 3) * tile_size)
			var ry = rd.rect.position.y * tile_size + margin + randf() * ((rd.rect.size.y - 3) * tile_size)
			prop.position = Vector2(rx, ry)
			# 隨機小角度旋轉，顯得凌亂自然
			prop.rotation = randf_range(-0.3, 0.3)
			prop_instances.append(prop)

# ── 尋路網格動態建立 ──────────────────────────────────────
func _setup_navigation() -> void:
	var nav_region = get_node_or_null("NavigationRegion2D")
	if nav_region:
		nav_region.queue_free()
		await get_tree().process_frame
		
	nav_region = NavigationRegion2D.new()
	nav_region.name = "NavigationRegion2D"
	add_child(nav_region)
	
	var nav_poly = NavigationPolygon.new()
	
	# 將所有地板方塊作為 outline 加入
	for y in gen.map_height:
		for x in gen.map_width:
			if gen.is_floor(x, y):
				# 使用無邊距，以便相鄰地板自動 union 合併
				var p0 = Vector2(x * tile_size, y * tile_size)
				var p1 = Vector2((x + 1) * tile_size, y * tile_size)
				var p2 = Vector2((x + 1) * tile_size, (y + 1) * tile_size)
				var p3 = Vector2(x * tile_size, (y + 1) * tile_size)
				nav_poly.add_outline(PackedVector2Array([p0, p1, p2, p3]))
				
	nav_poly.make_polygons_from_outlines()
	nav_region.navigation_polygon = nav_poly

