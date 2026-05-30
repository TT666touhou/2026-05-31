@tool
extends PointLight2D
class_name ProceduralLight

const TEX_RES: int = 512
const FOG_TEX_RES: int = 8  # Small uniform texture for fog ambient light

# ─── Vision Light ─────────────────────────────────────────────────────────────
@export_group("Vision Light")
@export_range(0.0, 2000.0) var ambient_radius: float = 100.0:
	set(v): ambient_radius = v; _queue_update()
@export_range(0.0, 500.0) var ambient_blur: float = 40.0:
	set(v): ambient_blur = v; _queue_update()
@export_range(0.0, 2000.0) var cone_radius: float = 350.0:
	set(v): cone_radius = v; _queue_update()
@export_range(0.0, 500.0) var cone_blur: float = 80.0:
	set(v): cone_blur = v; _queue_update()
@export_range(0.0, 180.0) var cone_angle: float = 30.0:
	set(v): cone_angle = v; _queue_update()

# ─── Fog of War ───────────────────────────────────────────────────────────────
# 霧色濾鏡：在視野外提供低亮度、低飽和的環境光，讓玩家能隱約看到地形。
# 敵人因為在不同的 light_mask 層，不會被此光照到，保持完全不可見。
@export_group("Fog of War")

## 霧中亮度（0 = 全黑，1 = 全亮），建議值 0.05 ~ 0.15
@export_range(0.0, 1.0, 0.01) var fog_brightness: float = 0.08:
	set(v): fog_brightness = v; _update_fog_light()

## 霧的色調。設為偏灰色（r=g=b）可降低飽和度；可調整為冷藍或暖橙帶來不同氣氛
@export var fog_tint: Color = Color(0.5, 0.52, 0.58):
	set(v): fog_tint = v; _update_fog_light()

## 霧光照射的 Layer 遮罩（哪些物件在霧中可見）。
## 預設 2 = 只照牆壁/門（light_mask=2），不照敵人（light_mask=1，保持全黑）
@export_flags_2d_render var fog_item_mask: int = 2:
	set(v): fog_item_mask = v; _update_fog_light()

## 霧光覆蓋半徑（像素），要大於整個地圖可見範圍即可
@export_range(500.0, 10000.0, 100.0) var fog_radius: float = 4000.0:
	set(v): fog_radius = v; _update_fog_light()

# ─── Private ──────────────────────────────────────────────────────────────────
var _update_queued: bool = false
var _fog_light: PointLight2D = null
var _fog_tex: ImageTexture = null

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	if not Engine.is_editor_hint():
		_setup_fog_light()
	_queue_update()

# ─── Vision texture ───────────────────────────────────────────────────────────
func _queue_update() -> void:
	if not _update_queued:
		_update_queued = true
		call_deferred("_update_texture")

func _update_texture() -> void:
	_update_queued = false
	
	var max_r = max(ambient_radius + ambient_blur, cone_radius + cone_blur)
	if max_r <= 0.0:
		self.texture = null
		return
		
	var scale_factor = (TEX_RES * 0.5) / max_r
	self.texture_scale = max_r / (TEX_RES * 0.5)
	
	var img = Image.create_empty(TEX_RES, TEX_RES, false, Image.FORMAT_L8)
	var center = Vector2(TEX_RES * 0.5, TEX_RES * 0.5)
	
	for y in range(TEX_RES):
		for x in range(TEX_RES):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center) / scale_factor
			
			var ambient_val = 0.0
			if dist <= ambient_radius:
				ambient_val = 1.0
			elif dist < ambient_radius + ambient_blur:
				ambient_val = 1.0 - ((dist - ambient_radius) / ambient_blur)
				
			var cone_val = 0.0
			if dist <= cone_radius + cone_blur:
				var dir = pos - center
				var angle = rad_to_deg(abs(dir.angle()))
				
				if angle <= cone_angle:
					cone_val = 1.0
				elif angle < cone_angle + (cone_blur * 0.5):
					cone_val = 1.0 - ((angle - cone_angle) / (cone_blur * 0.5))
					
				if dist > cone_radius:
					cone_val *= max(0.0, 1.0 - ((dist - cone_radius) / cone_blur))
			
			var final_val = max(ambient_val, cone_val)
			if final_val > 0.0:
				var c = int(clamp(final_val, 0.0, 1.0) * 255.0)
				img.set_pixel(x, y, Color8(c, c, c, 255))
				
	if self.texture is ImageTexture and self.texture.get_width() == TEX_RES and self.texture.get_height() == TEX_RES:
		self.texture.update(img)
	else:
		self.texture = ImageTexture.create_from_image(img)

# ─── Fog of War light ─────────────────────────────────────────────────────────
func _setup_fog_light() -> void:
	# 清除舊節點（重複進入場景時）
	var existing = get_parent().get_node_or_null("_FogAmbientLight")
	if existing:
		existing.queue_free()
	
	# 建立一個超大型的環境霧光，覆蓋整個地圖
	_fog_light = PointLight2D.new()
	_fog_light.name = "_FogAmbientLight"
	_fog_light.shadow_enabled = false
	_fog_light.blend_mode = Light2D.BLEND_MODE_ADD
	
	# 建立小型純白紋理（fog light 不需要漸層）
	var img = Image.create_empty(FOG_TEX_RES, FOG_TEX_RES, false, Image.FORMAT_L8)
	img.fill(Color.WHITE)
	_fog_tex = ImageTexture.create_from_image(img)
	_fog_light.texture = _fog_tex
	
	# 加到 Player 節點下（跟 VisionLight 同層），這樣會跟著玩家移動
	get_parent().add_child(_fog_light)
	_update_fog_light()

func _update_fog_light() -> void:
	if not is_instance_valid(_fog_light):
		return
	_fog_light.color = fog_tint
	_fog_light.energy = fog_brightness
	_fog_light.range_item_cull_mask = fog_item_mask
	# texture_scale = 直徑 / 紋理尺寸
	_fog_light.texture_scale = (fog_radius * 2.0) / float(FOG_TEX_RES)

