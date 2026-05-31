extends Node
class_name VisibilityComponent

@export var fov_degrees: float = 90.0
@export var view_distance: float = 600.0
@export var edge_offset: float = 12.0 # The offset for left/right raycasts
@export var fade_duration: float = 0.15

var target: Node2D
var parent: CanvasItem
var current_visibility: float = 0.0

func _ready() -> void:
	parent = get_parent() as CanvasItem
	parent.modulate.a = 0.0
	parent.visible = false
	
	# We need to find the player to track
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
	else:
		# Fallback to finding by name if group isn't set yet
		var scene = get_tree().current_scene
		if scene:
			target = scene.get_node_or_null("Player")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or not is_instance_valid(parent):
		return
		
	var target_visibility = 0.0
	var dist = parent.global_position.distance_to(target.global_position)
	
	if dist <= view_distance:
		var dir_to_parent = (parent.global_position - target.global_position).normalized()
		
		var aim_dir = Vector2.RIGHT
		if target.get("current_aim_direction") != null:
			aim_dir = target.current_aim_direction
			
		var angle_diff = rad_to_deg(abs(aim_dir.angle_to(dir_to_parent)))
		
		# If within FOV angle, perform multi-point raycast
		if angle_diff <= fov_degrees / 2.0:
			var perpendicular = Vector2(-dir_to_parent.y, dir_to_parent.x) * edge_offset
			
			var test_points = [
				parent.global_position,
				parent.global_position + perpendicular,
				parent.global_position - perpendicular
			]
			
			var hits_clear = 0
			var space_state = parent.get_world_2d().direct_space_state
			
			for pt in test_points:
				var query = PhysicsRayQueryParameters2D.create(target.global_position, pt)
				query.collision_mask = 1 # Assuming walls are on layer 1
				query.exclude = [target.get_rid(), parent.get_rid()] if parent is CollisionObject2D else [target.get_rid()]
				
				var result = space_state.intersect_ray(query)
				if not result:
					hits_clear += 1
			
			if hits_clear > 0:
				target_visibility = 1.0

	# Smoothly fade alpha
	if current_visibility != target_visibility:
		current_visibility = move_toward(current_visibility, target_visibility, delta / fade_duration)
		parent.modulate.a = current_visibility
		
		if current_visibility > 0.0:
			parent.visible = true
		else:
			parent.visible = false
