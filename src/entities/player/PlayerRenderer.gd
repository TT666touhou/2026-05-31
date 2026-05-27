## PlayerRenderer — Top-down stick figure renderer.
## @tool allows live preview in the Godot editor.
## Right arm tracks the mouse; left arm mirrors. Dash leaves afterimages.
@tool
class_name PlayerRenderer
extends Node2D

# ─── Visual Exports ──────────────────────────────────────────────────────────
@export var head_color: Color = Color("#F5E6C8"):
	set(v): head_color = v; queue_redraw()

@export var head_radius: float = 11.0:
	set(v): head_radius = maxf(4.0, v); queue_redraw()

@export var outline_color: Color = Color("#1A1A2E"):
	set(v): outline_color = v; queue_redraw()

@export var outline_width: float = 2.5:
	set(v): outline_width = maxf(0.5, v); queue_redraw()

@export var arm_color: Color = Color("#F5E6C8"):
	set(v): arm_color = v; queue_redraw()

@export var arm_length: float = 20.0:
	set(v): arm_length = maxf(8.0, v); queue_redraw()

@export var arm_width: float = 3.5:
	set(v): arm_width = maxf(1.0, v); queue_redraw()

@export var hand_size: float = 4.5:
	set(v): hand_size = maxf(2.0, v); queue_redraw()

@export_category("Animation")
@export var arm_sway_amplitude: float = 12.0
@export var arm_sway_speed: float = 6.0

@export_category("Eye Direction")
@export var show_eyes: bool = true:
	set(v): show_eyes = v; queue_redraw()
@export var eye_color: Color = Color("#1A1A2E"):
	set(v): eye_color = v; queue_redraw()
@export var eye_offset: float = 3.5

# ─── Runtime State (set by PlayerController) ────────────────────────────────
var right_arm_angle: float = 0.0
var left_arm_angle: float  = PI
var is_moving: bool        = false
var look_direction: Vector2 = Vector2.RIGHT

# ─── Afterimage Pool ─────────────────────────────────────────────────────────
const MAX_AFTERIMAGES: int = 3
var _afterimages: Array[Dictionary] = []
var _sway_time: float = 0.0

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	_afterimages.clear()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_sway_time += delta if is_moving else -delta * 2.0
	_sway_time = clampf(_sway_time, 0.0, TAU)

	for i: int in range(_afterimages.size() - 1, -1, -1):
		_afterimages[i]["alpha"] -= delta * 5.0
		if _afterimages[i]["alpha"] <= 0.0:
			_afterimages.remove_at(i)

	queue_redraw()

# ─── Public API ──────────────────────────────────────────────────────────────
func spawn_afterimage() -> void:
	if _afterimages.size() >= MAX_AFTERIMAGES:
		_afterimages.remove_at(0)
	_afterimages.append({
		"position":  global_position,
		"right_arm": right_arm_angle,
		"left_arm":  left_arm_angle,
		"alpha":     0.30,
	})

# ─── Drawing ─────────────────────────────────────────────────────────────────
func _draw() -> void:
	# Afterimages (behind)
	for img: Dictionary in _afterimages:
		var local_pos: Vector2 = to_local(img["position"])
		_draw_figure(local_pos, img["right_arm"], img["left_arm"],
			Color(head_color.r, head_color.g, head_color.b, img["alpha"]),
			Color(arm_color.r, arm_color.g, arm_color.b, img["alpha"] * 0.7))

	# Main figure
	var sway: float = sin(_sway_time * arm_sway_speed) * deg_to_rad(arm_sway_amplitude) if is_moving else 0.0
	_draw_figure(Vector2.ZERO, right_arm_angle + sway, left_arm_angle - sway, head_color, arm_color)

func _draw_figure(pos: Vector2, r_angle: float, l_angle: float,
				  h_color: Color, a_color: Color) -> void:
	# Shadow blob (visible even on dark bg)
	draw_circle(pos + Vector2(2, 3), head_radius * 0.85, Color(0, 0, 0, 0.25))

	# Left arm
	var l_end: Vector2 = pos + Vector2.from_angle(l_angle) * arm_length
	draw_line(pos, l_end, outline_color, arm_width + 2.0, true)
	draw_line(pos, l_end, a_color, arm_width, true)

	# Right arm (sword hand)
	var r_end: Vector2 = pos + Vector2.from_angle(r_angle) * arm_length
	draw_line(pos, r_end, outline_color, arm_width + 2.0, true)
	draw_line(pos, r_end, a_color, arm_width, true)

	# Head outline → fill
	draw_circle(pos, head_radius + outline_width, outline_color)
	draw_circle(pos, head_radius, h_color)

	# Eyes
	if show_eyes and h_color.a > 0.15:
		var fwd: Vector2   = look_direction
		var right: Vector2 = Vector2(-fwd.y, fwd.x)
		draw_circle(pos + fwd * (head_radius * 0.45) - right * eye_offset * 0.5, 2.0, eye_color)
		draw_circle(pos + fwd * (head_radius * 0.45) + right * eye_offset * 0.5, 2.0, eye_color)
