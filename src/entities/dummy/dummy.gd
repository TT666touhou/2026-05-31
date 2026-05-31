extends CharacterBody2D
class_name Dummy

@onready var health = $HealthComponent
@onready var hurtbox = $HurtboxComponent
@onready var drawer = $ProceduralDrawer

var _vision_light: Node = null  # ProceduralLight ref

func _ready() -> void:
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)
	# Cache VisionLight from player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_vision_light = players[0].get_node_or_null("VisionLight")
	
func _physics_process(delta: float) -> void:
	# Add simple gravity so it stays on the ground if in a platformer, or just friction for top-down
	velocity = velocity.move_toward(Vector2.ZERO, 800 * delta)
	move_and_slide()




func _on_health_changed(old_val: float, new_val: float) -> void:
	var dmg = old_val - new_val
	print("Dummy took ", dmg, " damage! Health: ", new_val)

func _on_hit_received(damage: float, knockback: Vector2) -> void:
	print("Dummy Hit! Damage: ", damage, ", Knockback: ", knockback)
	
	velocity += knockback # Apply true physics knockback
	
	if drawer and "target_facing_angle" in drawer:
		if knockback.length_squared() > 0.1:
			var new_target = (-knockback).angle()
			print("Dummy Knockback valid. Updating target_facing_angle from ", drawer.target_facing_angle, " to ", new_target)
			drawer.target_facing_angle = new_target
		else:
			print("Dummy Knockback too small, ignoring turn.")
	
	# Spawn damage number
	var label = Label.new()
	label.text = str(round(damage))
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_font_size_override("font_size", 12)
	label.global_position = global_position + Vector2(randf_range(-20, 20), -60)
	get_tree().current_scene.add_child(label)
	
	var tween = label.create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -50), 0.5).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tween.tween_callback(label.queue_free)

func _on_died() -> void:
	print("Dummy reached 0 health, but it is immortal!")
	# Reset health to full so it can keep being tested
	health.current_health = health.max_health
