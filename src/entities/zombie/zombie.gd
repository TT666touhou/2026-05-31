extends CharacterBody2D

enum State {
	IDLE,
	CHASE,
	ATTACK,
	DEAD
}

@export var move_speed: float = 50.0
@export var sight_range: float = 400.0
@export var attack_range: float = 45.0

var current_state: State = State.IDLE
var target_player: Node2D = null
var _vision_light: Node = null  # ProceduralLight ref

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var drawer = $ProceduralDrawer
@onready var health_comp = $HealthComponent
@onready var hurtbox_comp = $HurtboxComponent
@onready var health_bar = $UI/HealthBar

var knockback_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	health_comp.connect("health_changed", Callable(self, "_on_health_changed"))
	health_comp.connect("died", Callable(self, "_on_died"))
	if hurtbox_comp:
		hurtbox_comp.connect("hit_received", Callable(self, "_on_hit_received"))
		
	health_bar.max_value = health_comp.max_health
	health_bar.value = health_comp.current_health
	health_bar.hide()
	
	# Wait for first physics frame so nav server is synced
	call_deferred("_setup_nav")

func _setup_nav() -> void:
	# Find player and cache VisionLight reference
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]
		_vision_light = target_player.get_node_or_null("VisionLight")

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
		
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
			
	if knockback_velocity.length() > 10.0:
		# Apply high friction to knockback
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1500.0 * delta)
		# Override velocity to act as stun/knockback
		velocity = knockback_velocity
			
	move_and_slide()
	_update_visibility()
	
	# Push rigid bodies (like unlocked doors)
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var collider = c.get_collider()
		if collider is RigidBody2D:
			# Apply impulse to push open doors or push ragdolls
			var push_force = 400.0
			var offset = c.get_position() - collider.global_position
			collider.apply_impulse(-c.get_normal() * push_force, offset)

func _process_idle(_delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 200.0 * _delta)
	drawer.is_attacking = false
	
	if target_player and global_position.distance_to(target_player.global_position) <= sight_range:
		current_state = State.CHASE

func _process_chase(delta: float) -> void:
	drawer.is_attacking = false
	if not target_player:
		current_state = State.IDLE
		return
		
	var dist_to_player = global_position.distance_to(target_player.global_position)
	if dist_to_player <= attack_range:
		current_state = State.ATTACK
		return
	elif dist_to_player > sight_range * 1.5:
		current_state = State.IDLE
		return
		
	nav_agent.target_position = target_player.global_position
	
	if nav_agent.is_navigation_finished():
		velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
		print("Zombie: nav finished. Pos: ", global_position)
		return
		
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = global_position.direction_to(next_path_pos)
	
	velocity = dir * move_speed
	
	print("Zombie Chase: Pos: ", global_position, " NextPath: ", next_path_pos, " Vel: ", velocity, " IsNavFinished: ", nav_agent.is_navigation_finished())
	
	# Look towards moving direction or player directly if close
	drawer.target_facing_angle = global_position.direction_to(target_player.global_position).angle()

func _process_attack(_delta: float) -> void:
	if not target_player:
		current_state = State.IDLE
		return
		
	var dist_to_player = global_position.distance_to(target_player.global_position)
	if dist_to_player > attack_range + 10.0:
		current_state = State.CHASE
		return
		
	# Continue moving towards player to grab them
	var dir = global_position.direction_to(target_player.global_position)
	velocity = dir * move_speed
	
	# Trigger attack visuals in drawer (hands will reach out to grab)
	drawer.is_attacking = true
	drawer.attack_target = target_player.global_position
	drawer.target_facing_angle = global_position.direction_to(target_player.global_position).angle()

func _update_visibility() -> void:
	if not _vision_light or not _vision_light.has_method("is_in_vision"):
		return
	var in_vision: bool = _vision_light.is_in_vision(global_position, self)
	drawer.visible = in_vision
	$UI.visible = in_vision

func _on_health_changed(_old_health: float, new_health: float) -> void:
	health_bar.value = new_health
	health_bar.show()

func _on_hit_received(_damage: float, knockback: Vector2) -> void:
	knockback_velocity = knockback

func _on_died() -> void:
	current_state = State.DEAD
	health_bar.hide()
	
	# Disable collisions with player/other enemies (only keep terrain which is layer 1/mask 1)
	collision_layer = 0
	collision_mask = 1
	
	if $HitboxComponent:
		$HitboxComponent.queue_free()
	if $HurtboxComponent:
		$HurtboxComponent.queue_free()
		
	# Disable AI pathfinding
	set_physics_process(false)
	
	# Turn into a Ragdoll!
	# By clearing motors, the physics points are no longer forced to follow the center of the CharacterBody2D
	if drawer and drawer.verlet:
		drawer.verlet.motors.clear()
