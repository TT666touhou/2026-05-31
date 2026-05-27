## class_name RoomFloor
## Decorative floor fill. No collision — just visual ground texture.
## Place UNDER wall pieces to fill the walkable area.
@tool
class_name RoomFloor
extends Node2D

# ─── Exports ────────────────────────────────────────────────────────────────
@export var floor_width: float = 256.0:
	set(v):
		floor_width = maxf(16.0, v)
		queue_redraw()

@export var floor_height: float = 256.0:
	set(v):
		floor_height = maxf(16.0, v)
		queue_redraw()

@export var floor_color: Color = Color("#3D2B08"):
	set(v):
		floor_color = v
		queue_redraw()

@export var dot_color: Color = Color("#2A1E05"):
	set(v):
		dot_color = v
		queue_redraw()

@export var dot_spacing: float = 8.0:
	set(v):
		dot_spacing = maxf(4.0, v)
		queue_redraw()

@export var show_dots: bool = true:
	set(v):
		show_dots = v
		queue_redraw()

# ─── Drawing ─────────────────────────────────────────────────────────────────
func _draw() -> void:
	var rect: Rect2 = Rect2(-floor_width * 0.5, -floor_height * 0.5, floor_width, floor_height)
	draw_rect(rect, floor_color)

	if not show_dots:
		return
	var x: float = rect.position.x + dot_spacing
	while x < rect.end.x:
		var y: float = rect.position.y + dot_spacing
		while y < rect.end.y:
			draw_circle(Vector2(x, y), 1.2, dot_color)
			y += dot_spacing
		x += dot_spacing
