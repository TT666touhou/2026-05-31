extends Node2D
class_name WoodDoor

@export var is_locked: bool = false
@export var ajar_angle: float = 15.0 # The default "unlocked/crooked" angle

var interactable: InteractableComponent
@onready var door_body: RigidBody2D = $DoorBody

func _ready() -> void:
	add_to_group("trackable")
	interactable = get_node_or_null("DoorBody/InteractableComponent")
	if interactable:
		interactable.interacted.connect(_on_interacted)
		
	_apply_lock_state()

func _on_interacted() -> void:
	is_locked = not is_locked
	_apply_lock_state()

func _apply_lock_state() -> void:
	if is_locked:
		door_body.freeze = true
		
		# Create a linear tween to return the door to 0 degrees smoothly
		var tween = create_tween()
		tween.tween_property(door_body, "rotation_degrees", 0.0, 0.25).set_trans(Tween.TRANS_LINEAR)
	else:
		door_body.freeze = false
		if abs(door_body.rotation_degrees) < 5.0:
			# If it's freshly unlocked and mostly closed, push it slightly ajar
			door_body.rotation_degrees = ajar_angle

# ── Trackable interface ────────────────────────────────────────────────────────
func _get_vision_check_position() -> Vector2:
	# Use DoorBody's position for vision check (the swinging part)
	return door_body.global_position

func get_vision_snapshot() -> Dictionary:
	var visuals: Node = door_body.get_node_or_null("Visuals")
	return {
		"type": "WoodDoor",
		"global_transform": door_body.global_transform,
		"door_size": visuals.door_size if visuals and "door_size" in visuals else Vector2(10, 40),
	}

func set_vision_visible(v: bool) -> void:
	var visuals: Node = door_body.get_node_or_null("Visuals")
	if visuals:
		visuals.visible = v
