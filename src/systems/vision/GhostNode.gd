## GhostNode.gd
## Renders a frozen "last known state" of an interactive object.
## Created by VisionTracker when an object leaves the player's vision.
extends Node2D

var _snapshot: Dictionary = {}
var _wood_tex: Texture2D
var _stone_tex: Texture2D
var _table_tex: Texture2D

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	_wood_tex  = load("res://assets/textures/wood_door.png")
	_stone_tex = load("res://assets/textures/stone_door.png")
	_table_tex = load("res://assets/textures/wood_table.png")

func setup(snapshot: Dictionary) -> void:
	_snapshot = snapshot
	global_transform = snapshot.get("global_transform", Transform2D.IDENTITY)
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
	if not _wood_tex:
		return
	var door_size: Vector2 = _snapshot.get("door_size", Vector2(10, 40))
	var rect := Rect2(-door_size.x / 2.0, -door_size.y / 2.0, door_size.x, door_size.y)
	draw_texture_rect(_wood_tex, rect, false)

# ── StoneDoor ─────────────────────────────────────────────────────────────────
func _draw_stone_door() -> void:
	var door_size: Vector2 = _snapshot.get("door_size", Vector2(10, 40))
	var sink_progress: float = _snapshot.get("sink_progress", 0.0)

	if sink_progress > 0.0:
		var full_rect := Rect2(-door_size.x / 2.0, -door_size.y / 2.0, door_size.x, door_size.y)
		draw_rect(full_rect, Color(0.05, 0.05, 0.05))

	if sink_progress < 1.0 and _stone_tex:
		var visible_h := door_size.y * (1.0 - sink_progress)
		var dest_rect := Rect2(-door_size.x / 2.0, door_size.y / 2.0 - visible_h, door_size.x, visible_h)
		var tex_h := float(_stone_tex.get_height())
		var src_rect := Rect2(0, sink_progress * tex_h, float(_stone_tex.get_width()), (1.0 - sink_progress) * tex_h)
		draw_texture_rect_region(_stone_tex, dest_rect, src_rect)

# ── WoodTable ─────────────────────────────────────────────────────────────────
func _draw_wood_table() -> void:
	if not _table_tex:
		return
	var table_size: Vector2 = _snapshot.get("table_size", Vector2(30, 20))
	var rect := Rect2(-table_size / 2.0, table_size)
	draw_texture_rect(_table_tex, rect, false)
