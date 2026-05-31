extends Area2D
class_name Arrow

var speed: float = 800.0
var direction: Vector2 = Vector2.ZERO
var is_stuck: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if has_node("HitboxComponent"):
		var hitbox = $HitboxComponent
		hitbox.activate()
		hitbox.hit_landed.connect(_on_hitbox_hit_landed)

func fire(dir: Vector2, custom_speed: float = 800.0) -> void:
	direction = dir.normalized()
	speed = custom_speed
	rotation = direction.angle()
	
	if has_node("HitboxComponent"):
		$HitboxComponent.knockback_direction_override = direction

func _physics_process(delta: float) -> void:
	if not is_stuck:
		position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if is_stuck: return
	
	if body.collision_layer & 1 != 0: # Hit terrain
		_stick_to(body)

func _on_hitbox_hit_landed(target: Node2D) -> void:
	if is_stuck: return
	_stick_to(target)

func _stick_to(target_node: Node2D) -> void:
	is_stuck = true
	
	if has_node("HitboxComponent"):
		$HitboxComponent.deactivate()
		
	# 為了避免因為物理幀速度太快導致箭矢插得太深，強制將箭矢往反方向拉出一段隨機距離
	# 讓箭尖盡量停留在表面，並增加插深插淺的隨機感
	global_position -= direction * randf_range(12.0, 22.0)
	
	# Safely reparent deferred to avoid physics callback errors
	call_deferred("reparent", target_node)
	
	# Automatically remove after 10 seconds
	get_tree().create_timer(10.0).timeout.connect(queue_free)

func _draw() -> void:
	# Draw arrow shaft
	draw_line(Vector2(-10, 0), Vector2(10, 0), Color.WHITE, 1.0)
	# Draw arrowhead
	draw_line(Vector2(5, -3), Vector2(10, 0), Color.WHITE, 1.0)
	draw_line(Vector2(5, 3), Vector2(10, 0), Color.WHITE, 1.0)
	# Draw fletching
	draw_line(Vector2(-10, 0), Vector2(-12, -2), Color.WHITE, 1.0)
	draw_line(Vector2(-10, 0), Vector2(-12, 2), Color.WHITE, 1.0)
