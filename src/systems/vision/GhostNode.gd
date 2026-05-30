## GhostNode.gd
## Renders a frozen "last known state" of an interactive object.
## Created by VisionTracker when an object leaves the player's vision.
extends Node2D

var _snapshot: Dictionary = {}

func setup(snapshot: Dictionary) -> void:
	_snapshot = snapshot
	global_transform = snapshot.get("global_transform", Transform2D.IDENTITY)
	# light_mask = 3: visible in both FogLight (layer 1) and VisionLight (layer 2)
	light_mask = 3
	queue_redraw()

func _draw() -> void:
	if _snapshot.is_empty():
		return
	match _snapshot.get("type", ""):
		"WoodDoor":
			_draw_wood_door()
		"StoneDoor":
			_draw_stone_door()
		"WoodTable":
			_draw_wood_table()

# ── WoodDoor ──────────────────────────────────────────────────────────────────
func _draw_wood_door() -> void:
	var door_size: Vector2 = _snapshot.get("door_size", Vector2(10, 40))
	var wood_rect := Rect2(-door_size.x / 2.0, -door_size.y / 2.0, door_size.x, door_size.y)

	draw_rect(wood_rect, Color(0.45, 0.28, 0.16))

	# Vertical planks
	var plank_width := 3.3
	var x := wood_rect.position.x
	while x < wood_rect.position.x + wood_rect.size.x:
		draw_line(Vector2(x, wood_rect.position.y),
			Vector2(x, wood_rect.position.y + wood_rect.size.y),
			Color(0.2, 0.1, 0.05), 1.0)
		x += plank_width

	# Iron bands
	draw_line(
		Vector2(wood_rect.position.x, wood_rect.position.y + wood_rect.size.y * 0.15),
		Vector2(wood_rect.position.x + wood_rect.size.x, wood_rect.position.y + wood_rect.size.y * 0.15),
		Color(0.15, 0.15, 0.15), 2.0)
	draw_line(
		Vector2(wood_rect.position.x, wood_rect.position.y + wood_rect.size.y * 0.85),
		Vector2(wood_rect.position.x + wood_rect.size.x, wood_rect.position.y + wood_rect.size.y * 0.85),
		Color(0.15, 0.15, 0.15), 2.0)

# ── StoneDoor ─────────────────────────────────────────────────────────────────
func _draw_stone_door() -> void:
	var door_size: Vector2 = _snapshot.get("door_size", Vector2(10, 40))
	var sink_progress: float = _snapshot.get("sink_progress", 0.0)

	var rect := Rect2(-door_size / 2.0, door_size)

	if sink_progress > 0.0:
		draw_rect(rect, Color(0.05, 0.05, 0.05))
		draw_rect(rect, Color(0.0, 0.0, 0.0), false, 1.0)

	if sink_progress < 1.0:
		var visible_h: float = door_size.y * (1.0 - sink_progress)
		var door_rect := Rect2(-door_size.x / 2.0,
			door_size.y / 2.0 - visible_h, door_size.x, visible_h)
		draw_rect(door_rect, Color(0.22, 0.22, 0.23))

		var line_col := Color(0.08, 0.08, 0.09)
		draw_line(Vector2(door_rect.position.x, door_rect.position.y),
			Vector2(door_rect.end.x, door_rect.position.y), line_col, 2.0)
		draw_line(Vector2(door_rect.position.x, door_rect.position.y),
			Vector2(door_rect.position.x, door_rect.end.y), line_col, 2.0)
		draw_line(Vector2(door_rect.end.x, door_rect.position.y),
			Vector2(door_rect.end.x, door_rect.end.y), line_col, 2.0)

		var center_y: float = door_rect.position.y + visible_h / 2.0
		if center_y > door_rect.position.y + 2 and center_y < door_rect.end.y - 2:
			draw_line(Vector2(-door_size.x / 2.0 + 2, center_y),
				Vector2(door_size.x / 2.0 - 2, center_y), line_col, 1.5)

# ── WoodTable ─────────────────────────────────────────────────────────────────
func _draw_wood_table() -> void:
	var table_size: Vector2 = _snapshot.get("table_size", Vector2(30, 20))
	var rect := Rect2(-table_size / 2.0, table_size)

	draw_rect(rect, Color(0.45, 0.28, 0.16))

	# Planks
	var plank_width := 15.0
	var y := -table_size.y / 2.0
	while y < table_size.y / 2.0:
		draw_line(Vector2(-table_size.x / 2.0, y),
			Vector2(table_size.x / 2.0, y),
			Color(0.2, 0.1, 0.05), 1.0)
		y += plank_width
