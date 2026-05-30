@tool
extends Node2D
class_name FloorSegment

@export var grid_size: Vector2i = Vector2i(1, 1):
	set(value):
		grid_size = value
		if grid_size.x < 1: grid_size.x = 1
		if grid_size.y < 1: grid_size.y = 1
		queue_redraw()

const GRID_CELL_SIZE = 10.0

@export var base_color: Color = Color(0.18, 0.18, 0.18, 1.0)
@export var mortar_color: Color = Color(0.05, 0.05, 0.05, 1.0)
@export var highlight_color: Color = Color(0.28, 0.28, 0.28, 1.0)

func _ready() -> void:
	# Floor should be drawn behind entities
	z_index = -10
	# Put floor on light layer 2 so fog ambient light (fog_item_mask=2) can illuminate it
	# Enemies are on default layer 1, so they stay invisible in fog
	light_mask = 2
	queue_redraw()

func _draw() -> void:
	var w = grid_size.x * GRID_CELL_SIZE
	var h = grid_size.y * GRID_CELL_SIZE
	var rect = Rect2(0, 0, w, h)
	
	# Base background
	draw_rect(rect, base_color)
	
	seed(int(global_position.x + global_position.y * 1000))
	
	# Draw floor tiles (matched to wall brick size)
	var brick_w = 20
	var brick_h = 10
	
	for x in range(0, int(w) + brick_w, brick_w):
		for y in range(0, int(h) + brick_h, brick_h):
			var offset_x = int(brick_w / 2.0) if int(y / float(brick_h)) % 2 == 1 else 0
			var px = x - offset_x
			
			if px < w and y < h:
				# Reliable positioning: Clamp coordinates to ensure no lines bleed outside the rect
				var start_x = clamp(px, 0.0, float(w))
				var end_x = clamp(px + brick_w, 0.0, float(w))
				if start_x != end_x:
					_draw_rough_line(Vector2(start_x, y), Vector2(end_x, y), mortar_color, 2.0)
					
				if px >= 0 and px <= w:
					var start_y = clamp(y, 0.0, float(h))
					var end_y = clamp(y + brick_h, 0.0, float(h))
					if start_y != end_y:
						_draw_rough_line(Vector2(px, start_y), Vector2(px, end_y), mortar_color, 2.0)
						
			# Add subtle noise/cracks inside the tile sometimes
			if randf() > 0.85:
				var cx = clamp(px + randf_range(2, brick_w-2), 0.0, float(w))
				var cy = clamp(y + randf_range(2, brick_h-2), 0.0, float(h))
				if cx > 0 and cx < w and cy > 0 and cy < h:
					var cx2 = clamp(cx + randf_range(-4, 4), 0.0, float(w))
					var cy2 = clamp(cy + randf_range(-4, 4), 0.0, float(h))
					_draw_rough_line(Vector2(cx, cy), Vector2(cx2, cy2), mortar_color, 1.0)
				
	# Cap the bottom and right edges so it aligns cleanly
	_draw_rough_line(Vector2(0, h), Vector2(w, h), mortar_color, 2.0)
	_draw_rough_line(Vector2(w, 0), Vector2(w, h), mortar_color, 2.0)

func _draw_rough_line(p1: Vector2, p2: Vector2, color: Color, base_thickness: float) -> void:
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
		var offset = normal * randf_range(-0.5, 0.5)
		var thickness = base_thickness * randf_range(0.5, 1.5)
		
		draw_line(current_pos, next_pos + offset, color, thickness)
		current_pos = next_pos + offset
		current_dist += step
