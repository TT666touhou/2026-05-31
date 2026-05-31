## PlayerFOV — PointLight2D 玩家視野光源
## blend_mode 必須是 MIX，才能在黑暗 CanvasModulate 下顯示地面顏色。
## 光源顏色根據真實 Darkwood 截圖像素分析所得（暖橙色調）。
class_name PlayerFOV
extends PointLight2D

# ─── Exports ────────────────────────────────────────────────────────────────
@export var view_radius: float = 280.0:
	set(v):
		view_radius = maxf(50.0, v)
		_apply_radius()

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	# ★ 必須是 MIX：在 CanvasModulate 暗化的畫面上「顯示」正確色彩
	#   ADD 模式只會在黑色上加亮，導致視野內也偏色
	blend_mode = PointLight2D.BLEND_MODE_MIX

	# 生成柔和漸層貼圖（邊緣淡出）
	texture       = LightTextureGenerator.generate_radial(256)
	texture_scale = view_radius / 128.0

	# ── 核心修正：Darkwood 暖橙光源色 ──────────────────
	# 根據真實截圖像素分析：光源核心區域 R=164 G=121 B=110
	# 正規化比值 R/G/B ≈ 1.35 / 1.00 / 0.90
	# 映射到 0-1 範圍並稍微提升飽和度
	color  = Color(1.0, 0.73, 0.62, 1.0)   # 暖橙/琥珀色
	energy = 1.15                           # 略強，填補暗區

	# ── 陰影設定 ────────────────────────────────────────
	# shadow_color 設為視野外的暗區色（非純黑）
	# 真實暗區平均：R≈19 G≈19 B≈19 → Color(0.074, 0.074, 0.074)
	shadow_enabled = true
	shadow_filter  = PointLight2D.SHADOW_FILTER_PCF5
	shadow_color   = Color(0.074, 0.073, 0.072, 1.0)   # ★ 與 CanvasModulate 完全一致

func _apply_radius() -> void:
	if not is_inside_tree():
		return
	texture_scale = view_radius / 128.0
