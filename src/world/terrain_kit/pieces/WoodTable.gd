@tool
extends RigidBody2D

@export var table_size: Vector2 = Vector2(30, 20):
	set(value):
		table_size = value
		_update_collision()
		queue_redraw()

var collision: CollisionShape2D

func _ready() -> void:
	collision = get_node_or_null("CollisionShape2D")
	_update_collision()
	if not Engine.is_editor_hint():
		add_to_group("trackable")

func _update_collision() -> void:
	if collision and collision.shape is RectangleShape2D:
		collision.shape.size = table_size

func _draw() -> void:
	var rect = Rect2(-table_size/2, table_size)
	
	# Base table color
	draw_rect(rect, Color(0.45, 0.28, 0.16))
	
	seed(int(global_position.x + global_position.y))
	
	# Draw wood planks
	var plank_width = 15.0
	for y in range(-table_size.y/2, table_size.y/2, int(plank_width)):
		draw_line(Vector2(-table_size.x/2, y), Vector2(table_size.x/2, y), Color(0.2, 0.1, 0.05), 1.0)
		
		# Draw some wood grain / noise
		for i in range(3):
			var px = randf_range(-table_size.x/2 + 2, table_size.x/2 - 2)
			var py = y + randf_range(2, plank_width - 2)
			if py > table_size.y/2 - 1: py = table_size.y/2 - 1
			var px2 = px + randf_range(10, 30)
			if px2 > table_size.x/2 - 2: px2 = table_size.x/2 - 2
			draw_line(Vector2(px, py), Vector2(px2, py), Color(0.3, 0.15, 0.08), 1.0)

# ── Trackable interface ────────────────────────────────────────────────────────
func get_vision_snapshot() -> Dictionary:
	return {
		"type": "WoodTable",
		"global_transform": global_transform,
		"table_size": table_size,
	}

func set_vision_visible(v: bool) -> void:
	visible = v
