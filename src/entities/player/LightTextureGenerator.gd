## LightTextureGenerator — generates gradient textures for PointLight2D at runtime.
## Supports both radial (360-degree) and directional cone (flashlight) shapes.
class_name LightTextureGenerator
extends RefCounted

# ── 全圓形漸層（原有）──────────────────────────────────
static func generate_radial(size: int = 256) -> ImageTexture:
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size * 0.5, size * 0.5)
	var radius: float = size * 0.5

	for y: int in size:
		for x: int in size:
			var dist: float = Vector2(x, y).distance_to(center)
			var t: float = clampf(dist / radius, 0.0, 1.0)
			# Smooth falloff: 1 at center, 0 at edge
			var alpha: float = 1.0 - smoothstep(0.0, 1.0, t)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	return ImageTexture.create_from_image(img)

# ── 扇形方向光錐（Darkwood 手電筒效果）────────────────
# cone_angle_deg：光錐開口角度（60 = 窄手電筒，100 = 燈籠，120 = 廣角）
# soft_edge：邊緣柔化程度（0.1 = 銳利，0.4 = 非常柔和）
static func generate_cone(size: int = 256, cone_angle_deg: float = 100.0, soft_edge: float = 0.25) -> ImageTexture:
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size * 0.5, size * 0.5)
	var radius: float   = size * 0.5
	
	# 光錐朝向右方（正 X 軸），玩家使用 PointLight2D.rotation 調整方向
	var half_angle: float = deg_to_rad(cone_angle_deg * 0.5)
	
	for y: int in size:
		for x: int in size:
			var offset: Vector2 = Vector2(x, y) - center
			var dist: float     = offset.length()
			
			if dist > radius or dist < 0.1:
				img.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
				continue
			
			# 計算此像素相對中心的角度（絕對值，對稱光錐）
			var pixel_angle: float = abs(offset.angle())  # 0 ~ PI
			
			# 超出光錐範圍的部分用 smoothstep 淡出
			var angle_t: float    = clampf((pixel_angle - half_angle) / (half_angle * soft_edge + 0.001), 0.0, 1.0)
			var angle_alpha: float = 1.0 - smoothstep(0.0, 1.0, angle_t)
			
			# 距離衰減（靠近邊緣變暗）
			var dist_t: float     = clampf(dist / radius, 0.0, 1.0)
			var dist_alpha: float = 1.0 - smoothstep(0.55, 1.0, dist_t)
			
			# 中心有輕微環境光補償（確保玩家身邊有小圓形亮區）
			var center_fill: float = 1.0 - smoothstep(0.0, 0.15, dist_t)
			
			var final_alpha: float = maxf(angle_alpha * dist_alpha, center_fill * 0.7)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(final_alpha, 0.0, 1.0)))
	
	return ImageTexture.create_from_image(img)
