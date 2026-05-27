extends Area2D
class_name Arrow

var speed: float = 800.0
var direction: Vector2 = Vector2.ZERO
var is_stuck: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func fire(dir: Vector2, custom_speed: float = 800.0) -> void:
	direction = dir.normalized()
	speed = custom_speed
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if not is_stuck:
		position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if is_stuck: return
	
	if body.collision_layer & 1 != 0: # Hit wall
		is_stuck = true
		# It just stays there
	elif body.collision_layer & 4 != 0: # Hit Enemy? (Assuming enemy is layer 3/layer mask 4)
		# deal damage, etc.
		if body.has_method("take_damage"):
			body.take_damage(10)
		queue_free()

func _draw() -> void:
	# Draw arrow shaft
	draw_line(Vector2(-10, 0), Vector2(10, 0), Color.WHITE, 1.0)
	# Draw arrowhead
	draw_line(Vector2(5, -3), Vector2(10, 0), Color.WHITE, 1.0)
	draw_line(Vector2(5, 3), Vector2(10, 0), Color.WHITE, 1.0)
	# Draw fletching
	draw_line(Vector2(-10, 0), Vector2(-12, -2), Color.WHITE, 1.0)
	draw_line(Vector2(-10, 0), Vector2(-12, 2), Color.WHITE, 1.0)
