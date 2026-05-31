extends Node

var hit_spark_scene = preload("res://src/systems/combat/HitSpark.tscn")
var camera_shake_intensity: float = 0.0
var camera_shake_duration: float = 0.0

func _process(delta: float) -> void:
	if camera_shake_duration > 0:
		camera_shake_duration -= delta
		var cam = get_viewport().get_camera_2d()
		if cam:
			if camera_shake_duration <= 0:
				cam.offset = Vector2.ZERO
			else:
				var damp = camera_shake_duration / 0.2
				var shake = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * camera_shake_intensity * damp
				cam.offset = shake

func apply_hitstop(duration: float = 0.08) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration * 0.05, true, false, true).timeout
	Engine.time_scale = 1.0

func screen_shake(intensity: float = 5.0, duration: float = 0.2) -> void:
	camera_shake_intensity = intensity
	camera_shake_duration = duration

func spawn_hit_spark(pos: Vector2, knockback_dir: Vector2) -> void:
	if not hit_spark_scene: return
	var spark = hit_spark_scene.instantiate()
	spark.global_position = pos
	spark.rotation = knockback_dir.angle()
	var root = get_tree().current_scene
	if root:
		root.add_child(spark)
	else:
		add_child(spark)
