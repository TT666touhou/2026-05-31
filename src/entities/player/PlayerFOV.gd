## PlayerFOV — PointLight2D that creates the player's field of view (flashlight in darkness).
## blend_mode MUST be MIX (not ADD) so it reveals terrain colour through CanvasModulate.
## Generates a soft radial gradient texture at startup — no external assets needed.
class_name PlayerFOV
extends PointLight2D

# ─── Exports ────────────────────────────────────────────────────────────────
@export var view_radius: float = 280.0:
	set(v):
		view_radius = maxf(50.0, v)
		_apply_radius()

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	# ★ CRITICAL: MIX mode reveals terrain under dark CanvasModulate.
	#   ADD mode only adds brightness on top of black = everything stays black.
	blend_mode = PointLight2D.BLEND_MODE_MIX

	# Generate soft circular gradient texture
	texture = LightTextureGenerator.generate_radial(256)
	texture_scale = view_radius / 128.0

	color    = Color(1.0, 1.0, 1.0, 1.0)
	energy   = 1.0

	# Enable shadow casting so walls block the light
	shadow_enabled = true
	shadow_filter  = PointLight2D.SHADOW_FILTER_PCF5   # Less expensive than PCF13
	shadow_color   = Color(0.04, 0.03, 0.06, 0.85)        # 深暨紫黑，略透

func _apply_radius() -> void:
	if not is_inside_tree():
		return
	texture_scale = view_radius / 128.0
