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

var _update_queued: bool = false

func _queue_update() -> void:
	if not _update_queued:
		_update_queued = true
		call_deferred("_update_texture")

func _ready() -> void:
	_update_queued = false
	_update_texture()

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

# Returns true if world_pos is inside the vision cone/ambient circle
# (geometric check only — no wall raycast).
# Use this for interactive objects (doors, tables) that sit near walls.
func is_in_vision_range(world_pos: Vector2) -> bool:
	var local_pos: Vector2 = to_local(world_pos)
	var dist: float = local_pos.length()
	if dist <= ambient_radius:
		return true
	if dist <= cone_radius:
		var angle_deg: float = rad_to_deg(abs(local_pos.angle()))
		if angle_deg <= cone_angle:
			return true
	return false

# Returns true if world_pos is inside the vision area
# AND there is no wall between this light and world_pos.
# Use this for enemies (zombies, dummies) — excludes their own body from raycast.
func is_in_vision(world_pos: Vector2, exclude_body: Object = null) -> bool:
	if not is_in_vision_range(world_pos):
		return false

	# --- Raycast check (wall occlusion) ---
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		world_pos,
		1  # collision_mask: wall layer (StaticBody2D default = 1)
	)
	if exclude_body is CollisionObject2D:
		query.exclude = [exclude_body.get_rid()]
	var result: Dictionary = space.intersect_ray(query)
	return result.is_empty()
