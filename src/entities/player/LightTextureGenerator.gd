## LightTextureGenerator — generates a radial gradient texture for PointLight2D at runtime.
## This gives the player FOV a soft circular glow rather than a hard-edged circle.
class_name LightTextureGenerator
extends RefCounted

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
