@tool
extends Node2D
class_name DoorVisuals

@export_enum("Wood", "Stone") var material_type: int = 0:
	set(value):
		material_type = value
		queue_redraw()

@export var door_size: Vector2 = Vector2(10, 20):
	set(value):
		door_size = value
		queue_redraw()

var sink_progress: float = 0.0

func set_sink_progress(progress: float) -> void:
	sink_progress = progress
	queue_redraw()

func _ready() -> void:
	pass

func _draw() -> void:
	var rect = Rect2(-door_size/2, door_size)
	
	if material_type == 0: # Wood
		var wood_rect = Rect2(-door_size.x/2, -door_size.y/2, door_size.x, door_size.y)
		draw_rect(wood_rect, Color(0.45, 0.28, 0.16)) # Match WoodTable base color
		
		# Draw vertical wood planks
		var plank_width = 3.3
		for x in range(wood_rect.position.x, wood_rect.position.x + wood_rect.size.x, int(plank_width)):
			draw_line(Vector2(x, wood_rect.position.y), Vector2(x, wood_rect.position.y + wood_rect.size.y), Color(0.2, 0.1, 0.05), 1.0)
			
		# Iron bands (top and bottom)
		draw_line(Vector2(wood_rect.position.x, wood_rect.position.y + wood_rect.size.y * 0.15), Vector2(wood_rect.position.x + wood_rect.size.x, wood_rect.position.y + wood_rect.size.y * 0.15), Color(0.15, 0.15, 0.15), 2.0)
		draw_line(Vector2(wood_rect.position.x, wood_rect.position.y + wood_rect.size.y * 0.85), Vector2(wood_rect.position.x + wood_rect.size.x, wood_rect.position.y + wood_rect.size.y * 0.85), Color(0.15, 0.15, 0.15), 2.0)
		
	else: # Stone
		# Draw the recess (hole) left behind when sinking
		if sink_progress > 0.0:
			draw_rect(rect, Color(0.05, 0.05, 0.05)) # Deep hole color
			# Inner shadow/border for recess
			draw_rect(rect, Color(0.0, 0.0, 0.0), false, 1.0)
			
		if sink_progress < 1.0:
			var visible_h = door_size.y * (1.0 - sink_progress)
			var door_rect = Rect2(-door_size.x/2, door_size.y/2 - visible_h, door_size.x, visible_h)
			
			draw_rect(door_rect, Color(0.22, 0.22, 0.23)) # Slightly distinct stone color
			
			seed(int(global_position.x + global_position.y))
			
			var line_col = Color(0.08, 0.08, 0.09)
			
			# Draw a thick carved border around the slab
			_draw_rough_line(Vector2(door_rect.position.x, door_rect.position.y), Vector2(door_rect.end.x, door_rect.position.y), line_col, 2.0)
			_draw_rough_line(Vector2(door_rect.position.x, door_rect.position.y), Vector2(door_rect.position.x, door_rect.end.y), line_col, 2.0)
			_draw_rough_line(Vector2(door_rect.end.x, door_rect.position.y), Vector2(door_rect.end.x, door_rect.end.y), line_col, 2.0)
			
			# Add random surface cracks
			for i in range(4):
				var p1 = Vector2(randf_range(-door_size.x/2 + 2, door_size.x/2 - 2), randf_range(door_rect.position.y + 2, door_rect.end.y - 2))
				var p2 = p1 + Vector2(randf_range(-4, 4), randf_range(-8, 8))
				p2.x = clamp(p2.x, -door_size.x/2 + 1, door_size.x/2 - 1)
				p2.y = clamp(p2.y, door_rect.position.y + 1, door_rect.end.y - 1)
				_draw_rough_line(p1, p2, Color(0.15, 0.15, 0.16), 1.0)
				
			# Draw a distinct horizontal groove in the center to signify it's a mechanical door
			var center_y = door_rect.position.y + visible_h / 2.0
			if center_y > door_rect.position.y + 2 and center_y < door_rect.end.y - 2:
				_draw_rough_line(Vector2(-door_size.x/2 + 2, center_y), Vector2(door_size.x/2 - 2, center_y), line_col, 1.5)
				_draw_rough_line(Vector2(-door_size.x/4, center_y - 2), Vector2(door_size.x/4, center_y + 2), line_col, 1.5)

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
		var offset = normal * randf_range(-0.5, 0.5)
		var thickness = base_thickness * randf_range(0.5, 1.5)
		
		draw_line(current_pos, next_pos + offset, color, thickness)
		current_pos = next_pos + offset
		current_dist += step
