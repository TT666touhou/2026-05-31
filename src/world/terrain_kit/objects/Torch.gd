## Torch — atmospheric flickering light source with warm orange glow.
## Place anywhere in the scene. All parameters adjustable in Inspector.
@tool
class_name Torch
extends Node2D

# ─── Exports ────────────────────────────────────────────────────────────────
@export var flame_color: Color = Color("#FF8C00"):
	set(v):
		flame_color = v
		queue_redraw()
		_update_light()

@export var light_radius: float = 140.0:
	set(v):
		light_radius = maxf(20.0, v)
		_update_light()

@export var light_energy: float = 1.1:
	set(v):
		light_energy = maxf(0.0, v)
		_base_energy = v
		_update_light()

@export var flicker: bool = true

# ─── State ──────────────────────────────────────────────────────────────────
var _time: float = 0.0
var _base_energy: float = 1.1

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	_base_energy = light_energy
	# Generate and assign texture to the PointLight2D child
	var pt: PointLight2D = get_node_or_null("PointLight2D")
	if pt:
		pt.texture = LightTextureGenerator.generate_radial(128)
		pt.blend_mode = PointLight2D.BLEND_MODE_MIX
		pt.shadow_enabled = false   # Torches don't cast shadow (perf)
	_update_light()

func _process(delta: float) -> void:
	if flicker and not Engine.is_editor_hint():
		_time += delta
		var flicker_val: float = (
			sin(_time * 7.3) * 0.07 +
			sin(_time * 11.9) * 0.04 +
			sin(_time * 3.1) * 0.03
		)
		var pt: PointLight2D = get_node_or_null("PointLight2D")
		if pt:
			pt.energy = maxf(0.2, _base_energy + flicker_val)

func _draw() -> void:
	# Torch body
	draw_rect(Rect2(-3, 0, 6, 14), Color("#3D2508"), true)
	# Flame glow
	draw_circle(Vector2(0, -4), 7.0, Color(flame_color.r, flame_color.g, flame_color.b, 0.4))
	draw_circle(Vector2(0, -4), 5.0, flame_color)
	draw_circle(Vector2(0, -8), 3.5, Color(1.0, 0.92, 0.5, 0.85))

# ─── Internal ────────────────────────────────────────────────────────────────
func _update_light() -> void:
	if not is_inside_tree():
		return
	var pt: PointLight2D = get_node_or_null("PointLight2D")
	if not pt:
		return
	pt.color   = flame_color
	pt.energy  = _base_energy
	# texture_scale: the texture is 128px wide, we want it to cover light_radius px
	pt.texture_scale = light_radius / 64.0
