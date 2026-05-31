extends Area2D
class_name InteractableComponent

signal interacted

var player_in_range: bool = false

func _ready() -> void:
	collision_layer = 128
	collision_mask = 2 # Player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			interacted.emit()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_E: # Allow right click or E if the player configures it
			pass

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController or body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body is PlayerController or body.is_in_group("player"):
		player_in_range = false
