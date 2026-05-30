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

var _floor_tex: Texture2D = null

func _ready() -> void:
	# Floor should be drawn behind entities
	z_index = -10
	var _tex_path = "res://assets/textures/stone_floor.png"
	if ResourceLoader.exists(_tex_path):
		_floor_tex = load(_tex_path)
	queue_redraw()

func _draw() -> void:
	var w = grid_size.x * GRID_CELL_SIZE
	var h = grid_size.y * GRID_CELL_SIZE
	var rect = Rect2(0, 0, w, h)
	
	if _floor_tex:
		draw_texture_rect(_floor_tex, rect, false)
	else:
		# Fallback: procedural grey fill
		draw_rect(rect, base_color)

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
