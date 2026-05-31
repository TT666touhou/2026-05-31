# DungeonLevel.gd
# 地下城主場景控制器
# 負責：生成地圖 → 渲染 → 放置玩家 → 放置敵人 → 管理 FOV

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

# ── 設定 ────────────────────────────────────────────────
@export var map_seed      : int  = 0          # 0 = 隨機
@export var map_width     : int  = 80
@export var map_height    : int  = 60
@export var tile_size     : int  = 64
@export var zombie_per_room: int = 2
@export var show_debug    : bool = false

# ── 狀態 ────────────────────────────────────────────────
var gen: DungeonGenerator
var player_instance: CharacterBody2D
var current_floor: int = 1

# ── 生命週期 ────────────────────────────────────────────
func _ready() -> void:
	generate_floor()

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
	
	# 2. 渲染地圖（程序繪製）
	dungeon_renderer.show_debug_rooms = show_debug
	dungeon_renderer.render(gen)
	
	# 3. 放置玩家
	_spawn_player()
	
	# 4. 放置敵人
	_spawn_enemies()
	
	# 5. 相機設定
	_setup_camera()

# ── 放置玩家在起始房間中心 ─────────────────────────────
func _spawn_player() -> void:
	if player_instance and is_instance_valid(player_instance):
		player_instance.queue_free()
	
	var start = gen.start_room
	if start == null and gen.rooms.size() > 0:
		start = gen.rooms[0]
	
	if start == null:
		push_error("DungeonLevel: No start room found!")
		return
	
	player_instance = PLAYER_SCENE.instantiate() as CharacterBody2D
	entities_layer.add_child(player_instance)
	player_instance.position = _room_center_world(start)
	
	# 相機跟隨玩家
	if camera:
		camera.reparent(player_instance)
		camera.position = Vector2.ZERO

# ── 放置敵人 ────────────────────────────────────────────
func _spawn_enemies() -> void:
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

# ── 清除所有實體 ────────────────────────────────────────
func _clear_entities() -> void:
	for child in entities_layer.get_children():
		child.queue_free()
	player_instance = null

# ── 相機設定 ────────────────────────────────────────────
func _setup_camera() -> void:
	if camera == null:
		return
	
	# 地圖邊界
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
