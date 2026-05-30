extends AnimatableBody2D
class_name BaseDoor

@export var is_open: bool = false
@export_enum("Swing", "Sink") var open_style: int = 0
@export var open_speed: float = 0.3
@export var swing_angle: float = 90.0

var original_rotation: float
var is_animating: bool = false
var sink_progress: float = 0.0 # 0 = fully closed (raised), 1 = fully open (sunk)

var visual_node: Node2D
var collision: CollisionShape2D
var original_collision_pos: Vector2
var occluder: LightOccluder2D
var interactable: InteractableComponent

func _ready() -> void:
	original_rotation = rotation_degrees
	
	collision = get_node_or_null("CollisionShape2D")
	if collision:
		original_collision_pos = collision.position
		
	occluder = get_node_or_null("LightOccluder2D")
	visual_node = get_node_or_null("Visuals")
	interactable = get_node_or_null("InteractableComponent")
	
	if interactable:
		interactable.interacted.connect(_on_interacted)
		
	_update_state(true) # instant snap
	_ready_trackable()  # register as trackable

func _on_interacted() -> void:
	if is_animating: return
	is_open = !is_open
	is_animating = true

func _process(delta: float) -> void:
	if is_animating:
		if open_style == 0: # Swing
			var target_rot = original_rotation + (swing_angle if is_open else 0.0)
			rotation_degrees = move_toward(rotation_degrees, target_rot, open_speed * delta * 100.0)
			if abs(rotation_degrees - target_rot) < 0.1:
				rotation_degrees = target_rot
				is_animating = false
				_apply_physics_state()
		else: # Sink
			var target_progress = 1.0 if is_open else 0.0
			sink_progress = move_toward(sink_progress, target_progress, open_speed * delta * 5.0)
			
			if visual_node.has_method("set_sink_progress"):
				visual_node.set_sink_progress(sink_progress)
			else:
				visual_node.modulate.a = lerpf(1.0, 0.2, sink_progress) # Default sink
				
			if collision:
				var h = visual_node.door_size.y if "door_size" in visual_node else 40.0
				collision.position.y = original_collision_pos.y + h * sink_progress
				
			if abs(sink_progress - target_progress) < 0.01:
				sink_progress = target_progress
				is_animating = false
				_apply_physics_state()

func _update_state(instant: bool) -> void:
	if instant:
		if open_style == 0:
			rotation_degrees = original_rotation + (swing_angle if is_open else 0.0)
		else:
			sink_progress = 1.0 if is_open else 0.0
			if visual_node.has_method("set_sink_progress"):
				visual_node.set_sink_progress(sink_progress)
			else:
				visual_node.modulate.a = lerpf(1.0, 0.2, sink_progress)
		is_animating = false
		_apply_physics_state()
	else:
		is_animating = true

func _apply_physics_state() -> void:
	if open_style == 0: # Only disable collision for Swing doors
		if collision:
			collision.disabled = is_open
			
	if occluder:
		occluder.visible = not is_open

# ── Trackable interface ────────────────────────────────────────────────────────
func _ready_trackable() -> void:
	add_to_group("trackable")

func get_vision_snapshot() -> Dictionary:
	return {
		"type": "StoneDoor",
		"global_transform": global_transform,
		"door_size": visual_node.door_size if visual_node and "door_size" in visual_node else Vector2(10, 40),
		"sink_progress": sink_progress,
	}

func set_vision_visible(v: bool) -> void:
	if visual_node:
		visual_node.visible = v
