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
		occ_poly.cull_mode = OccluderPolygon2D.CULL_COUNTER_CLOCKWISE
		light_occluder.occluder = occ_poly
		
	queue_redraw()

func _draw() -> void:
	var w = grid_size.x * GRID_CELL_SIZE
	var h = grid_size.y * GRID_CELL_SIZE
	
	draw_rect(Rect2(0, 0, w, h), base_color)
	
	# Draw rough edges/bricks scaled for 10px units
	var brick_w = 20
	var brick_h = 10
	
	for x in range(0, w + brick_w, brick_w):
		for y in range(0, h + brick_h, brick_h):
			var offset_x = int(brick_w / 2.0) if int(y / float(brick_h)) % 2 == 1 else 0
			var px = x - offset_x
			
			if px < w and y < h:
				# Reliable positioning: Clamp coordinates to ensure no lines bleed outside the rect
				var start_x = clamp(px, 0, w)
				var end_x = clamp(px + brick_w, 0, w)
				if start_x != end_x:
					_draw_rough_line(Vector2(start_x, y), Vector2(end_x, y), line_color)
					
				if px >= 0 and px <= w:
					var start_y = clamp(y, 0, h)
					var end_y = clamp(y + brick_h, 0, h)
					if start_y != end_y:
						_draw_rough_line(Vector2(px, start_y), Vector2(px, end_y), line_color)
				
	# Keep the outer edges completely clean by ensuring they draw strictly within 0~w and 0~h
	_draw_rough_line(Vector2(0, 0), Vector2(w, 0), highlight_color)
	_draw_rough_line(Vector2(0, 0), Vector2(0, h), highlight_color)
	_draw_rough_line(Vector2(w, 0), Vector2(w, h), line_color)
	_draw_rough_line(Vector2(0, h), Vector2(w, h), line_color)

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

