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
	var w = grid_size.x * GRID_CELL_SIZE
	var h = grid_size.y * GRID_CELL_SIZE
	# Walls are 10 px thick — no texture can show a complete brick at that scale.
	# Use solid dark charcoal matching Darkwood palette (#2a2826).
	draw_rect(Rect2(0, 0, w, h), Color(0.165, 0.157, 0.149, 1.0))
	# Subtle lighter top-edge for depth
	draw_line(Vector2(0, 0), Vector2(w, 0), Color(0.28, 0.26, 0.24, 0.6), 1.0)

