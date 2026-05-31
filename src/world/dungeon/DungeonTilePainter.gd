# DungeonTilePainter.gd
# 負責將 DungeonGenerator 的 tile_map 資料渲染到 Godot TileMapLayer
# 同時處理牆壁的 autotile / bitmask 選擇

class_name DungeonTilePainter
extends RefCounted

# TileSet 中各 tile 的 atlas 座標（對應 DungeonTileSet.tres）
# Atlas 0 = 程序繪製（不使用實際貼圖，用 CanvasItem 繪製）
const SOURCE_ID = 0

# 地板 atlas 座標
const FLOOR_COORDS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
]

# 牆壁 atlas 座標（單一實心牆）
const WALL_COORD  = Vector2i(3, 0)

# 房間類型顏色標記（用 CanvasModulate 子層）
const ROOM_TYPE_COLORS = {
	"start":    Color(0.2, 0.8, 0.2, 0.3),   # 綠色
	"normal":   Color(0.0, 0.0, 0.0, 0.0),    # 無標記
	"elite":    Color(0.8, 0.2, 0.8, 0.3),    # 紫色
	"treasure": Color(0.9, 0.8, 0.1, 0.3),    # 金色
	"shop":     Color(0.2, 0.5, 0.9, 0.3),    # 藍色
	"boss":     Color(0.9, 0.1, 0.1, 0.3),    # 紅色
}

var rng: RandomNumberGenerator

func _init() -> void:
	rng = RandomNumberGenerator.new()

# ── 主繪製入口 ──────────────────────────────────────────
func paint(
	gen: DungeonGenerator,
	floor_layer: TileMapLayer,
	wall_layer:  TileMapLayer,
	tile_set: TileSet
) -> void:
	rng.seed = gen.rng.seed
	
	floor_layer.tile_set = tile_set
	wall_layer.tile_set  = tile_set
	
	floor_layer.clear()
	wall_layer.clear()
	
	for y in gen.map_height:
		for x in gen.map_width:
			var t = gen.tile_map[y][x]
			var pos = Vector2i(x, y)
			
			if t == 0:   # 地板
				var atlas_coord = _pick_floor_tile(x, y, gen)
				floor_layer.set_cell(pos, SOURCE_ID, atlas_coord)
			elif t == 1: # 牆壁
				wall_layer.set_cell(pos, SOURCE_ID, WALL_COORD)

# ── 根據鄰居選擇地板變體（增加視覺多樣性）──────────────
func _pick_floor_tile(x: int, y: int, gen: DungeonGenerator) -> Vector2i:
	# 用座標當 seed 確保同一地圖每次看起來一樣
	var local_rng = RandomNumberGenerator.new()
	local_rng.seed = x * 1000 + y
	
	var roll = local_rng.randf()
	# 大部分用基本地板，少部分用變體
	if roll < 0.70:
		return FLOOR_COORDS[0]
	elif roll < 0.82:
		return FLOOR_COORDS[1]
	elif roll < 0.91:
		return FLOOR_COORDS[2]
	elif roll < 0.96:
		return FLOOR_COORDS[3]
	elif roll < 0.99:
		return FLOOR_COORDS[4]
	else:
		return FLOOR_COORDS[5]

# ── 清除地圖 ────────────────────────────────────────────
func clear(floor_layer: TileMapLayer, wall_layer: TileMapLayer) -> void:
	floor_layer.clear()
	wall_layer.clear()
