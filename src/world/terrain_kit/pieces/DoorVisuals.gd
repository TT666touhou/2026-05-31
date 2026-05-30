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

@export var wood_texture: Texture2D
@export var stone_texture: Texture2D

func set_sink_progress(progress: float) -> void:
	sink_progress = progress
	queue_redraw()


func _draw() -> void:
	if material_type == 0: # Wood
		if wood_texture:
			var wood_rect = Rect2(-door_size.x/2, -door_size.y/2, door_size.x, door_size.y)
			draw_texture_rect(wood_texture, wood_rect, false)
			
	else: # Stone
		var full_rect = Rect2(-door_size.x/2, -door_size.y/2, door_size.x, door_size.y)
		if sink_progress > 0.0:
			draw_rect(full_rect, Color(0.05, 0.05, 0.05)) # Dark pit
		
		if sink_progress < 1.0 and stone_texture:
			var visible_h = door_size.y * (1.0 - sink_progress)
			var dest_rect = Rect2(-door_size.x/2, door_size.y/2 - visible_h, door_size.x, visible_h)
			var tex_h = float(stone_texture.get_height())
			var src_rect = Rect2(0, sink_progress * tex_h, float(stone_texture.get_width()), (1.0 - sink_progress) * tex_h)
			draw_texture_rect_region(stone_texture, dest_rect, src_rect)

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
