## VisionTracker.gd
## Child node of Player. Monitors all "trackable" objects and manages
## GhostNode creation/destruction when objects leave/enter the player's vision.
extends Node

const GhostNodeScript = preload("res://src/systems/vision/GhostNode.gd")

# Map: trackable_node -> { "in_vision": bool, "ghost": Node2D | null }
var _tracked: Dictionary = {}

var _vision_light: Node = null  # ProceduralLight (VisionLight on Player)
var _scene_root: Node = null    # Where ghost nodes are added

func _ready() -> void:
	# Wait one frame so siblings are available
	call_deferred("_init_tracker")

func _init_tracker() -> void:
	_vision_light = get_parent().get_node_or_null("VisionLight")
	_scene_root = get_tree().current_scene
	if not _vision_light:
		push_warning("VisionTracker: VisionLight not found on Player.")

func _physics_process(_delta: float) -> void:
	if not _vision_light or not _vision_light.has_method("is_in_vision_range"):
		return

	# Discover newly added trackable objects each frame (cheap set-diff)
	for obj in get_tree().get_nodes_in_group("trackable"):
		if not _tracked.has(obj):
			_tracked[obj] = {"in_vision": true, "ghost": null}

	# Update each tracked object
	var to_remove: Array = []
	for obj in _tracked:
		if not is_instance_valid(obj):
			# Object was freed — clean up its ghost
			var entry = _tracked[obj]
			if entry["ghost"] != null and is_instance_valid(entry["ghost"]):
				entry["ghost"].queue_free()
			to_remove.append(obj)
			continue

		var entry: Dictionary = _tracked[obj]
		var check_pos: Vector2 = obj.global_position

		# For WoodDoor use DoorBody's position (PinJoint pivot is root pos)
		if obj.has_method("_get_vision_check_position"):
			check_pos = obj._get_vision_check_position()

		# Use geometric-only check (no raycast) — interactive objects sit near
		# walls and the raycast would falsely detect them as occluded.
		var now_visible: bool = _vision_light.is_in_vision_range(check_pos)
		var was_visible: bool = entry["in_vision"]

		if was_visible and not now_visible:
			_on_object_left_vision(obj, entry)
		elif not was_visible and now_visible:
			_on_object_entered_vision(obj, entry)

		entry["in_vision"] = now_visible

	for obj in to_remove:
		_tracked.erase(obj)

# ── Object Leaves Vision ──────────────────────────────────────────────────────
func _on_object_left_vision(obj: Node, entry: Dictionary) -> void:
	if not obj.has_method("get_vision_snapshot"):
		return

	# Collect snapshot from the object
	var snapshot: Dictionary = obj.get_vision_snapshot()

	# If snapshot is empty (visuals not ready), abort — keep real visual visible
	if snapshot.is_empty() or not snapshot.has("type"):
		return

	# Create ghost at scene root (so it doesn't move with the object)
	var ghost := Node2D.new()
	ghost.set_script(GhostNodeScript)
	_scene_root.add_child(ghost)
	ghost.setup(snapshot)

	entry["ghost"] = ghost

	# Hide the real visual so the object is invisible
	if obj.has_method("set_vision_visible"):
		obj.set_vision_visible(false)

# ── Object Enters Vision ──────────────────────────────────────────────────────
func _on_object_entered_vision(obj: Node, entry: Dictionary) -> void:
	# Destroy ghost
	if entry["ghost"] != null and is_instance_valid(entry["ghost"]):
		entry["ghost"].queue_free()
	entry["ghost"] = null

	# Show real visual again
	if obj.has_method("set_vision_visible"):
		obj.set_vision_visible(true)
