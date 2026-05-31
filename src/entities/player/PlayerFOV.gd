## PlayerFOV — Darkwood 風格方向性視野光錐
## 使用扇形光錐貼圖 + 自動跟隨滑鼠/移動方向旋轉
## blend_mode MUST be MIX — 讓光照區域顯示地形顏色，光照外則由 CanvasModulate 暗化
class_name PlayerFOV
extends PointLight2D

# ─── Exports ────────────────────────────────────────────────────────────────
@export var view_radius: float = 320.0:
	set(v):
		view_radius = maxf(80.0, v)
		_apply_radius()

## 光錐開口角度（度）。100 = 燈籠型，60 = 手電筒型，360 = 全圓
@export var cone_angle: float = 105.0:
	set(v):
		cone_angle = clampf(v, 20.0, 360.0)
		_rebuild_texture()

## 光源暖色（照明區的染色）
@export var light_color: Color = Color(1.0, 0.92, 0.76, 1.0)  # 暖橙黃（火炬色）

## 旋轉來源：跟隨滑鼠（true）或跟隨移動方向（false）
@export var follow_mouse: bool = true

# ─── 私有狀態 ────────────────────────────────────────────────────────────────
var _last_move_dir: Vector2 = Vector2.RIGHT
var _target_angle:  float  = 0.0
var _current_angle: float  = 0.0
const ROTATE_SPEED: float  = 10.0  # 旋轉跟隨速度（弧度/秒），避免生硬跳轉

# 輔助家具光照通道 (Layer 3)
var _furniture_light: PointLight2D = null

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	# ★ CRITICAL: MIX mode reveals terrain color through CanvasModulate dark overlay.
	blend_mode = PointLight2D.BLEND_MODE_MIX
	
	color  = light_color
	energy = 1.0
	
	# 主光照設定：照亮第 1、2 層 (地表與角色)，並在第 1、2 層投影陰影
	range_item_cull_mask = 3
	shadow_item_cull_mask = 3
	
	# 啟用陰影（牆壁的 LightOccluder2D 會截斷光線）
	shadow_enabled = true
	shadow_filter  = PointLight2D.SHADOW_FILTER_PCF5
	shadow_color   = Color(0.0, 0.0, 0.0, 1.0)  # 陰影完全黑
	
	# 動態建立輔助家具通道
	_setup_furniture_light()
	
	_rebuild_texture()

func _setup_furniture_light() -> void:
	if _furniture_light != null:
		return
	_furniture_light = PointLight2D.new()
	_furniture_light.name = "FurnitureLight"
	add_child(_furniture_light)
	
	# 家具光照通道專有設定：只照亮 Layer 3，且只在 Layer 3 投影陰影 (只會被牆壁 occluder 阻擋)
	_furniture_light.range_item_cull_mask = 4
	_furniture_light.shadow_item_cull_mask = 4
	
	# 其他屬性完全與主光照同步
	_furniture_light.blend_mode = blend_mode
	_furniture_light.color = color
	_furniture_light.energy = energy
	_furniture_light.shadow_enabled = shadow_enabled
	_furniture_light.shadow_filter = shadow_filter
	_furniture_light.shadow_color = shadow_color

func _process(delta: float) -> void:
	_update_direction(delta)

# ─── 方向更新 ────────────────────────────────────────────────────────────────
func _update_direction(delta: float) -> void:
	if follow_mouse:
		# 計算玩家全域座標 → 螢幕座標，再算向量指向滑鼠
		var player_screen_pos = get_viewport().get_canvas_transform() * global_position
		var mouse_screen_pos  = get_viewport().get_mouse_position()
		var dir = (mouse_screen_pos - player_screen_pos).normalized()
		if dir.length_squared() > 0.01:
			_target_angle = dir.angle()
	else:
		# 跟隨移動方向（由父節點 PlayerController 更新 _last_move_dir）
		if _last_move_dir.length_squared() > 0.01:
			_target_angle = _last_move_dir.angle()
	
	# 平滑旋轉（避免方向突然跳轉）
	_current_angle = lerp_angle(_current_angle, _target_angle, ROTATE_SPEED * delta)
	rotation = _current_angle

# ─── 由 PlayerController 呼叫：更新移動方向 ─────────────────────────────────
func set_move_direction(dir: Vector2) -> void:
	if dir.length_squared() > 0.01:
		_last_move_dir = dir.normalized()

# ─── 重建光錐貼圖 ────────────────────────────────────────────────────────────
func _rebuild_texture() -> void:
	if cone_angle >= 359.0:
		# 完整圓形（特殊情況：如室內壁燈）
		texture = LightTextureGenerator.generate_radial(256)
	else:
		texture = LightTextureGenerator.generate_cone(256, cone_angle, 0.25)
	
	# 同步貼圖給家具光照通道
	if _furniture_light:
		_furniture_light.texture = texture
		
	_apply_radius()

func _apply_radius() -> void:
	if not is_inside_tree():
		return
	texture_scale = view_radius / 128.0
	
	# 同步縮放給家具光照通道
	if _furniture_light:
		_furniture_light.texture_scale = texture_scale

