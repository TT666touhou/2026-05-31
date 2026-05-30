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

@export var floor_texture: Texture2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Floor should be drawn behind entities
	z_index = -10
	queue_redraw()

func _draw() -> void:
	var w = grid_size.x * GRID_CELL_SIZE
	var h = grid_size.y * GRID_CELL_SIZE
	var rect = Rect2(0, 0, w, h)
	
	if floor_texture:
		# Tile at 80 game px per repeat (240 screen px at zoom=3 → mipmap level ~2 → clear detail)
		var tile_px := 80.0
		var sc := tile_px / float(floor_texture.get_width())
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(sc, sc))
		draw_texture_rect(floor_texture, Rect2(0.0, 0.0, w / sc, h / sc), true)
		draw_set_transform(Vector2.ZERO)

