extends Node
class_name VisionTracker

## VisionTracker
## Attach to Player. Monitors all nodes in group "trackable".
## When a trackable leaves vision -> freeze its Visuals node, spawn a Ghost.
## When a trackable re-enters vision -> restore live Visuals, destroy Ghost.

# ── Tunable vision params (matched to VisionLight in CaveLevel) ──────────────
@export var ambient_radius: float = 50.0
@export var cone_radius: float    = 300.0
@export var cone_angle_deg: float = 10.0   # half-angle of the cone

# ── Internal state ────────────────────────────────────────────────────────────
# Dict[ Node2D -> { ghost: Node2D|null, visuals: Node2D|null, in_vision: bool } ]
var _states: Dictionary = {}

# Wall physics layer mask for line-of-sight raycasts
const WALL_MASK: int = 1

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Give the scene a frame to settle before we start tracking
	set_process(false)
	await get_tree().process_frame
	set_process(true)


func _process(_dt: float) -> void:
	var player := get_parent() as CharacterBody2D
	if player == null:
		return

	var player_pos := player.global_position
	# PlayerController stores current_aim_direction as a public var
	var aim_dir: Vector2 = Vector2.RIGHT
	if "current_aim_direction" in player:
		aim_dir = player.current_aim_direction

	for obj in get_tree().get_nodes_in_group("trackable"):
		if not is_instance_valid(obj):
			continue
		_update(obj as Node2D, player_pos, aim_dir)


# ── Per-object update ─────────────────────────────────────────────────────────
func _update(obj: Node2D, player_pos: Vector2, aim_dir: Vector2) -> void:
	# Resolve the Visuals node (WoodDoor stores it at DoorBody/Visuals)
	var visuals: Node2D = _get_visuals(obj)
	if visuals == null:
		return

	# Register state on first encounter
	if not _states.has(obj):
		_states[obj] = { "ghost": null, "visuals": visuals, "in_vision": false }

	var state: Dictionary = _states[obj]
	var now_visible: bool = _is_in_vision(obj.global_position, player_pos, aim_dir)

	if now_visible:
		# ── Entering / staying in vision ──────────────────────────────────
		if not state["in_vision"]:
			# Was hidden → restore real Visuals, destroy ghost
			_destroy_ghost(state)
			if is_instance_valid(visuals):
				visuals.visible = true
		state["in_vision"] = true

	else:
		# ── Leaving / staying outside vision ─────────────────────────────
		if state["in_vision"]:
			# Just left vision → spawn ghost at current transform, hide real Visuals
			if is_instance_valid(visuals) and visuals.visible:
				_spawn_ghost(state, visuals)
				visuals.visible = false
		state["in_vision"] = false

	_states[obj] = state


# ── Ghost lifecycle ───────────────────────────────────────────────────────────
func _spawn_ghost(state: Dictionary, visuals: Node2D) -> void:
	# Duplicate the Visuals Node2D (copies script + exported properties)
	var ghost: Node2D = visuals.duplicate(0)
	# Freeze at current world transform
	ghost.global_transform = visuals.global_transform
	# Only visible in fog layer (FogLight range_item_cull_mask = 1)
	ghost.light_mask = 1
	# Prevent DoorVisuals from calling queue_redraw() via its setters
	# by removing the script – the canvas commands drawn so far are retained
	# for this frame, but Godot will redraw using _draw().
	# Instead we keep the script but override it: we re-draw in the ghost
	# using the SAME script, same params, same transform → same result.
	# The trick: detach from DoorBody so it doesn't follow physics.
	get_tree().current_scene.add_child(ghost)
	state["ghost"] = ghost


func _destroy_ghost(state: Dictionary) -> void:
	if state.get("ghost") != null and is_instance_valid(state["ghost"]):
		state["ghost"].queue_free()
	state["ghost"] = null


# ── Vision check ──────────────────────────────────────────────────────────────
func _is_in_vision(obj_pos: Vector2, player_pos: Vector2, aim_dir: Vector2) -> bool:
	var dist: float = obj_pos.distance_to(player_pos)

	# 1. Ambient circle around player
	if dist <= ambient_radius:
		return _has_los(player_pos, obj_pos)

	# 2. Flashlight cone
	if dist <= cone_radius:
		if aim_dir.length_squared() > 0.01:
			var dir_to_obj: Vector2 = (obj_pos - player_pos).normalized()
			var angle: float = rad_to_deg(abs(aim_dir.normalized().angle_to(dir_to_obj)))
			if angle <= cone_angle_deg:
				return _has_los(player_pos, obj_pos)

	return false


func _has_los(from: Vector2, to: Vector2) -> bool:
	var space := get_tree().root.get_world_2d().direct_space_state
	if space == null:
		return true
	var params := PhysicsRayQueryParameters2D.create(from, to)
	params.collision_mask = WALL_MASK
	# Exclude the player body itself
	var parent := get_parent()
	if parent is CollisionObject2D:
		params.exclude = [parent.get_rid()]
	var hit := space.intersect_ray(params)
	return hit.is_empty()


# ── Helper: find the Visuals node regardless of scene hierarchy ───────────────
func _get_visuals(obj: Node2D) -> Node2D:
	# WoodDoor: root=Node2D, Visuals is at DoorBody/Visuals
	var v = obj.get_node_or_null("DoorBody/Visuals")
	if v:
		return v as Node2D
	# StoneDoor / others: Visuals is a direct child
	v = obj.get_node_or_null("Visuals")
	if v:
		return v as Node2D
	return null
