extends RigidBody2D
class_name ItemDrop

@export var item_data: ItemData

func _ready() -> void:
	# Add some initial random spin and toss
	angular_velocity = randf_range(-5.0, 5.0)
	linear_velocity = Vector2(randf_range(-100, 100), randf_range(-100, 100))

func setup(data: ItemData) -> void:
	item_data = data
	queue_redraw()

func _draw() -> void:
	if not item_data: return
	
	# Assume size is grid_size * 10 just to draw it physically smaller on the ground
	var w = item_data.grid_size.x * 20.0
	var h = item_data.grid_size.y * 20.0
	var size = Vector2(w, h)
	var pos = -size / 2.0
	
	var center = pos + size / 2.0
	for lines in item_data.icon_lines:
		var transformed_lines = PackedVector2Array()
		for pt in lines:
			var abs_pt = center + Vector2(pt.x * size.x, pt.y * size.y)
			transformed_lines.append(abs_pt)
		if transformed_lines.size() >= 2:
			draw_polyline(transformed_lines, Color.WHITE, 2.0)
