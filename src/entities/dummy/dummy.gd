extends CharacterBody2D
class_name Dummy

@onready var health = $HealthComponent
@onready var hurtbox = $HurtboxComponent
@onready var drawer = $ProceduralDrawer

func _ready() -> void:
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)
	
func _physics_process(delta: float) -> void:
	# Add simple gravity so it stays on the ground if in a platformer, or just friction for top-down
	velocity = velocity.move_toward(Vector2.ZERO, 800 * delta)
	move_and_slide()

func _on_health_changed(old_val: float, new_val: float) -> void:
	var dmg = old_val - new_val
	print("Dummy took ", dmg, " damage! Health: ", new_val)
	# Flash effect
	if drawer:
		var original_color = drawer.body_color
		drawer.body_color = Color.RED
		drawer.queue_redraw()
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(drawer):
			drawer.body_color = original_color
			drawer.queue_redraw()

func _on_hit_received(damage: float, knockback: Vector2) -> void:
	if drawer and "target_facing_angle" in drawer:
		# knockback points away from the source, so -knockback points TO the source.
		drawer.target_facing_angle = (-knockback).angle()
	
	# Spawn damage number
	var label = Label.new()
	label.text = str(round(damage))
	label.add_theme_color_override("font_color", Color.RED)
	label.add_theme_font_size_override("font_size", 24)
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
