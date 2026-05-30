@tool
extends PointLight2D
class_name ProceduralLight

@export var tex_size: int = 512:
	set(v): tex_size = max(64, v); call_deferred("_update_texture")
@export var ambient_radius: float = 100.0:
	set(v): ambient_radius = max(0.0, v); call_deferred("_update_texture")
@export var ambient_blur: float = 40.0:
	set(v): ambient_blur = max(0.0, v); call_deferred("_update_texture")
@export var cone_radius: float = 350.0:
	set(v): cone_radius = max(0.0, v); call_deferred("_update_texture")
@export var cone_blur: float = 80.0:
	set(v): cone_blur = max(0.0, v); call_deferred("_update_texture")
@export var cone_angle: float = 30.0:
	set(v): cone_angle = clamp(v, 0.0, 180.0); call_deferred("_update_texture")

func _ready() -> void:
	if texture == null or texture.get_size() != Vector2(tex_size, tex_size):
		_update_texture()

func _update_texture() -> void:
	if tex_size <= 0: return
	
	var img = Image.create_empty(tex_size, tex_size, false, Image.FORMAT_L8)
	img.fill(Color(0, 0, 0, 1))
	var center = Vector2(tex_size * 0.5, tex_size * 0.5)
	
	for y in range(tex_size):
		for x in range(tex_size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
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
			if final_val > 0:
				img.set_pixel(x, y, Color(final_val, final_val, final_val, 1.0))
				
	self.texture = ImageTexture.create_from_image(img)
