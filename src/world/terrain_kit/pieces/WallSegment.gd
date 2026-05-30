@tool
extends StaticBody2D
class_name WallSegment

@export var grid_size: Vector2i = Vector2i(1, 1):
	set(value):
		grid_size = value
		if grid_size.x < 1: grid_size.x = 1
		if grid_size.y < 1: grid_size.y = 1
		_update_visuals()

const GRID_CELL_SIZE = 10.0

@export var base_color: Color = Color(0.25, 0.25, 0.25, 1.0)
@export var line_color: Color = Color(0.05, 0.05, 0.05, 1.0)
@export var highlight_color: Color = Color(0.35, 0.35, 0.35, 1.0)

@export var wall_texture: Texture2D

var collision_poly: CollisionPolygon2D
var light_occluder: LightOccluder2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	collision_poly = get_node_or_null("CollisionPolygon2D")
	light_occluder = get_node_or_null("LightOccluder2D")

	_update_visuals()

func _update_visuals() -> void:
	var w = grid_size.x * GRID_CELL_SIZE
	var h = grid_size.y * GRID_CELL_SIZE
	
	if collision_poly:
		var pts = PackedVector2Array([
			Vector2(0, 0),
			Vector2(w, 0),
			Vector2(w, h),
			Vector2(0, h)
		])
		collision_poly.polygon = pts
		
	if light_occluder:
		var occ_poly = OccluderPolygon2D.new()
		occ_poly.polygon = PackedVector2Array([
			Vector2(0, 0),
			Vector2(w, 0),
			Vector2(w, h),
			Vector2(0, h)
		])
		occ_poly.cull_mode = OccluderPolygon2D.CULL_DISABLED
		light_occluder.occluder = occ_poly
		
	queue_redraw()

func _draw() -> void:
	var w = float(grid_size.x) * GRID_CELL_SIZE
	var h = float(grid_size.y) * GRID_CELL_SIZE

	if wall_texture:
		# Non-uniform tiling:
		#   X: tile 80 game px wide (good detail at zoom=3)
		#   Y: tile exactly as tall as wall (= h) so no brick cutoff
		var tile_w := 80.0
		var tile_h := h  # wall height = one full tile height → complete bricks
		var sc_x := tile_w / float(wall_texture.get_width())
		var sc_y := tile_h / float(wall_texture.get_height())
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(sc_x, sc_y))
		draw_texture_rect(wall_texture, Rect2(0.0, 0.0, w / sc_x, h / sc_y), true)
		draw_set_transform(Vector2.ZERO)
