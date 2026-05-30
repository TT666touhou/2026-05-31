## VisionManager — Autoload singleton for querying player vision.
## Enemies call VisionManager.is_in_vision(global_position) to check if they should be visible.
class_name VisionManager
extends Node

var _player_node: Node2D = null
var _vision_light: Node = null  # ProceduralLight

## Called by PlayerController to register the player and vision light.
func register_player(player: Node2D, light: Node) -> void:
	_player_node = player
	_vision_light = light

## Returns true if a world-space position is within the player's ambient vision circle.
## This is the radius used for ambient glow (ambient_radius), not the flashlight cone.
func is_in_vision(world_pos: Vector2) -> bool:
	if not is_instance_valid(_player_node):
		return false
	if not is_instance_valid(_vision_light):
		return false
	var dist: float = world_pos.distance_to(_player_node.global_position)
	var radius: float = _vision_light.get("ambient_radius") if _vision_light.get("ambient_radius") != null else 100.0
	return dist <= radius

## Returns the player's current world position, or Vector2.ZERO if not registered.
func get_player_position() -> Vector2:
	if is_instance_valid(_player_node):
		return _player_node.global_position
	return Vector2.ZERO

## Returns the ambient vision radius.
func get_vision_radius() -> float:
	if is_instance_valid(_vision_light) and _vision_light.get("ambient_radius") != null:
		return _vision_light.ambient_radius
	return 100.0
