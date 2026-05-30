@tool
extends RigidBody2D

@export var table_size: Vector2 = Vector2(30, 20):
	set(value):
		table_size = value
		_update_collision()
		queue_redraw()

var collision: CollisionShape2D
@export var table_texture: Texture2D

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
	
	if table_texture:
		draw_texture_rect(table_texture, rect, false)
	else:
		# Fallback: procedural wood
		draw_rect(rect, Color(0.45, 0.28, 0.16))
		var plank_width = 15.0
		for y in range(-table_size.y/2, table_size.y/2, int(plank_width)):
			draw_line(Vector2(-table_size.x/2, y), Vector2(table_size.x/2, y), Color(0.2, 0.1, 0.05), 1.0)

# ── Trackable interface ────────────────────────────────────────────────────────
func get_vision_snapshot() -> Dictionary:
	return {
		"type": "WoodTable",
		"global_transform": global_transform,
		"table_size": table_size,
	}

func set_vision_visible(v: bool) -> void:
	visible = v
