extends Area2D
class_name Arrow

var speed: float = 800.0
var direction: Vector2 = Vector2.ZERO
var is_stuck: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func fire(dir: Vector2, custom_speed: float = 800.0) -> void:
	direction = dir.normalized()
	speed = custom_speed
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if not is_stuck:
		position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if is_stuck: return
	
	if body.collision_layer & 1 != 0: # Hit terrain
		_stick_to(body)

func _on_area_entered(area: Area2D) -> void:
	if is_stuck: return
	
	if area is HurtboxComponent:
		var hurtbox = area as HurtboxComponent
		hurtbox.receive_hit(10.0, 100.0, global_position)
		_stick_to(hurtbox.get_parent())

func _stick_to(target_node: Node2D) -> void:
	is_stuck = true
	
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
