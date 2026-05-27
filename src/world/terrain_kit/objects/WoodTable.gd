## class_name WoodTable
## Decorative obstacle. Has collision and light occlusion. No scripts needed by enemies/player.
## Adjust size and wood grain appearance in Inspector.
@tool
class_name WoodTable
extends StaticBody2D

# ─── Exports ────────────────────────────────────────────────────────────────
@export var table_width: float = 80.0:
	set(v):
		table_width = maxf(16.0, v)
		_rebuild()

@export var table_height: float = 50.0:
	set(v):
		table_height = maxf(16.0, v)
		_rebuild()

@export var table_color: Color = Color("#5C3D0A"):
	set(v):
		table_color = v
		queue_redraw()

@export var grain_color: Color = Color(0.29, 0.19, 0.03, 0.4):
	set(v):
		grain_color = v
		queue_redraw()

@export var grain_spacing: float = 8.0:
	set(v):
		grain_spacing = maxf(4.0, v)
		queue_redraw()

@export var show_grain: bool = true:
	set(v):
		show_grain = v
		queue_redraw()

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_rebuild()

func _draw() -> void:
	var hw: float = table_width * 0.5
	var hh: float = table_height * 0.5
	draw_rect(Rect2(-hw, -hh, table_width, table_height), table_color)

	if show_grain:
		var y: float = -hh + grain_spacing
		while y < hh:
			draw_line(Vector2(-hw + 4, y), Vector2(hw - 4, y), grain_color, 1.0)
			y += grain_spacing

	# Thin outline
	draw_rect(Rect2(-hw, -hh, table_width, table_height), Color("#3D2508"), false, 2.0)

# ─── Internal ────────────────────────────────────────────────────────────────
func _rebuild() -> void:
	if not is_inside_tree():
		return
	var hw: float = table_width * 0.5
	var hh: float = table_height * 0.5
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw,  hh),  Vector2(-hw, hh),
	])

	var col_poly: CollisionPolygon2D = get_node_or_null("CollisionPolygon2D")
	if col_poly:
		col_poly.polygon = pts

	var occ: LightOccluder2D = get_node_or_null("LightOccluder2D")
	if occ and occ.occluder:
		occ.occluder.polygon = pts

	queue_redraw()
