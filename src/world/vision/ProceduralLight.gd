@tool
extends PointLight2D
class_name ProceduralLight

const TEX_RES: int = 512

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

# ── Fog of War 視野外色調 ──────────────────────────────────────────
# 分析參考圖：視野外亮度約 17-19%，帶冷藍綠色調
# RGB(40,48,43) normalized ≈ Color(0.157, 0.188, 0.169)
@export var fog_color: Color = Color(0.157, 0.188, 0.169):
	set(v):
		fog_color = v
		_apply_fog_color()

var _update_queued: bool = false

func _queue_update() -> void:
	if not _update_queued:
		_update_queued = true
		call_deferred("_update_texture")

func _ready() -> void:
	_queue_update()
	_apply_fog_color()

func _apply_fog_color() -> void:
	if not is_inside_tree():
		return
	# 找場景中的 CanvasModulate 並套用霧化顏色
	var modulate_node = get_tree().get_first_node_in_group("canvas_modulate")
	if not modulate_node:
		# 嘗試直接從父場景節點找
		var scene_root = get_tree().current_scene
		if scene_root:
			modulate_node = _find_canvas_modulate(scene_root)
	if modulate_node and modulate_node is CanvasModulate:
		modulate_node.color = fog_color

func _find_canvas_modulate(node: Node) -> Node:
	if node is CanvasModulate:
		return node
	for child in node.get_children():
		var result = _find_canvas_modulate(child)
		if result:
			return result
	return null

func _update_texture() -> void:
	_update_queued = false
	
	var max_r = max(ambient_radius + ambient_blur, cone_radius + cone_blur)
	if max_r <= 0.0:
		self.texture = null
		return
		
	# Keep texture generation fast by fixing it to TEX_RES and scaling the light
	var scale_factor = (TEX_RES * 0.5) / max_r
	self.texture_scale = max_r / (TEX_RES * 0.5)
	
	var img = Image.create_empty(TEX_RES, TEX_RES, false, Image.FORMAT_L8)
	var center = Vector2(TEX_RES * 0.5, TEX_RES * 0.5)
	
	# Generate pixels mapping coordinate space to logical distance
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
