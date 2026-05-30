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

var _wall_tex: Texture2D = null

var collision_poly: CollisionPolygon2D
var light_occluder: LightOccluder2D

func _ready() -> void:
	collision_poly = get_node_or_null("CollisionPolygon2D")
	light_occluder = get_node_or_null("LightOccluder2D")
	var _tex_path = "res://assets/textures/stone_wall.png"
	if ResourceLoader.exists(_tex_path):
		_wall_tex = load(_tex_path)
	
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
	var rect = Rect2(0, 0, w, h)
	
	if _wall_tex:
		draw_texture_rect(_wall_tex, rect, false)
	else:
		# Fallback: procedural grey fill
		draw_rect(rect, base_color)

func _draw_rough_line(p1: Vector2, p2: Vector2, color: Color, base_thickness: float = 1.0) -> void:
	var dist = p1.distance_to(p2)
	var dir = (p2 - p1).normalized()
	var normal = Vector2(-dir.y, dir.x)
	var current_dist = 0.0
	var current_pos = p1
	
	while current_dist < dist:
		var step = randf_range(2.0, 8.0)
		if current_dist + step > dist:
			step = dist - current_dist
		
		var next_pos = p1 + dir * (current_dist + step)
		# Add a tiny random offset to the normal for roughness
		var offset = normal * randf_range(-0.5, 0.5)
		var thickness = base_thickness * randf_range(0.5, 1.5)
		
		draw_line(current_pos, next_pos + offset, color, thickness)
		current_pos = next_pos + offset
		current_dist += step

