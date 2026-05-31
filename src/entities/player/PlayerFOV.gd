## PlayerFOV — PointLight2D that creates the player's field of view.
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
	#   ADD mode only adds brightness on top = no desaturation effect outside.
	blend_mode = PointLight2D.BLEND_MODE_MIX

	# Generate soft circular gradient texture
	texture = LightTextureGenerator.generate_radial(256)
	texture_scale = view_radius / 128.0

	# ── Darkwood 暖琥珀光源色彩（考察：火炬/燈籠的暖橙黃）
	# 對應 Darkwood 調色盤中視野內的暖色調 #FFC86B
	color  = Color(1.0, 0.78, 0.42, 1.0)
	energy = 1.4  # 夠穿透 0.22 的 ambient，視野內飽和顯示

	# ── 陰影：讓牆壁真正阻擋光線，強化視野錐的邊界感
	shadow_enabled = true
	shadow_filter  = PointLight2D.SHADOW_FILTER_PCF13  # 柔和陰影邊緣
	shadow_color   = Color(0.0, 0.0, 0.0, 1.0)         # 不透明陰影，強化對比

func _apply_radius() -> void:
	if not is_inside_tree():
		return
	texture_scale = view_radius / 128.0
