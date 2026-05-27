## SwordItem — Physics-aware sword with terrain collision blocking.
## When the sword's sweep arc hits a wall (collision layer 1), the swing is interrupted.
## Attach as child of Player's right hand position.
class_name SwordItem
extends Node2D

# ─── Exports ────────────────────────────────────────────────────────────────
@export var sword_length: float = 32.0
@export var sword_width: float = 5.0
@export var sword_color: Color = Color.WHITE
@export var grip_color: Color = Color("#8B4513")
@export var swing_arc_deg: float = 130.0     ## Total swing arc in degrees
@export var swing_speed: float = 9.0         ## Radians per second
@export var cooldown: float = 0.45           ## Seconds between attacks
@export var damage: float = 15.0            ## Damage dealt per swing
@export var terrain_mask: int = 1           ## Collision layer for walls

# ─── Signals ────────────────────────────────────────────────────────────────
signal swing_blocked(hit_point: Vector2)
signal swing_completed()

# ─── State ──────────────────────────────────────────────────────────────────
enum SwordState { IDLE, SWINGING, COOLDOWN }
var _state: SwordState = SwordState.IDLE
var _swing_start_angle: float = 0.0
var _swing_current_angle: float = 0.0
var _swing_end_angle: float = 0.0
var _cooldown_timer: float = 0.0

# ─── Node References ─────────────────────────────────────────────────────────
var _hitbox: HitboxComponent
var _shape_cast: ShapeCast2D

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	_hitbox = get_node_or_null("HitboxComponent") as HitboxComponent
	_shape_cast = get_node_or_null("TipCast") as ShapeCast2D
	if _hitbox:
		_hitbox.damage = damage
		_hitbox.deactivate()

func _process(delta: float) -> void:
	match _state:
		SwordState.IDLE:
			_process_idle()
		SwordState.SWINGING:
			_process_swing(delta)
		SwordState.COOLDOWN:
			_process_cooldown(delta)
	queue_redraw()

func _draw() -> void:
	if _state == SwordState.IDLE and _cooldown_timer <= 0.0:
		_draw_sword_at(0.0)
	else:
		_draw_sword_at(_swing_current_angle)

# ─── State Handlers ──────────────────────────────────────────────────────────
func _process_idle() -> void:
	if Input.is_action_just_pressed("attack") and _cooldown_timer <= 0.0:
		_begin_swing()

func _process_swing(delta: float) -> void:
	_swing_current_angle += swing_speed * delta

	# Check tip collision via ShapeCast
	if _shape_cast:
		_shape_cast.rotation = _swing_current_angle
		_shape_cast.force_shapecast_update()
		if _shape_cast.is_colliding():
			var hit: Vector2 = _shape_cast.get_collision_point(0)
			_interrupt_swing(hit)
			return

	# Swing complete?
	if _swing_current_angle >= _swing_end_angle:
		_swing_current_angle = _swing_end_angle
		_complete_swing()

func _process_cooldown(delta: float) -> void:
	_cooldown_timer -= delta
	if _cooldown_timer <= 0.0:
		_cooldown_timer = 0.0
		_state = SwordState.IDLE

# ─── Swing Logic ─────────────────────────────────────────────────────────────
func _begin_swing() -> void:
	_state = SwordState.SWINGING
	_swing_start_angle = -deg_to_rad(swing_arc_deg * 0.5)
	_swing_current_angle = _swing_start_angle
	_swing_end_angle = deg_to_rad(swing_arc_deg * 0.5)
	if _hitbox:
		_hitbox.activate()

func _complete_swing() -> void:
	if _hitbox: _hitbox.deactivate()
	_state = SwordState.COOLDOWN
	_cooldown_timer = cooldown
	swing_completed.emit()

func _interrupt_swing(hit_point: Vector2) -> void:
	if _hitbox: _hitbox.deactivate()
	_state = SwordState.COOLDOWN
	_cooldown_timer = cooldown
	swing_blocked.emit(hit_point)
	_spawn_spark(hit_point)

# ─── Drawing ─────────────────────────────────────────────────────────────────
func _draw_sword_at(angle: float) -> void:
	var dir: Vector2 = Vector2.from_angle(angle)
	var tip: Vector2 = dir * sword_length
	# Grip (short darker section near hand)
	draw_line(Vector2.ZERO, dir * 8.0, grip_color, sword_width + 2.0, true)
	# Blade
	draw_line(dir * 6.0, tip, sword_color, sword_width, true)
	# Tip
	draw_circle(tip, sword_width * 0.5, sword_color)

func _spawn_spark(at_pos: Vector2) -> void:
	# Simple spark: spawn a short-lived Node2D that draws white circles
	var spark: Node2D = Node2D.new()
	get_tree().current_scene.add_child(spark)
	spark.global_position = at_pos
	var tween: Tween = spark.create_tween()
	tween.tween_property(spark, "modulate:a", 0.0, 0.2)
	tween.tween_callback(spark.queue_free)
	# Draw a quick flash
	for i: int in 4:
		var dot: Node2D = Node2D.new()
		spark.add_child(dot)
		var rdir: Vector2 = Vector2.from_angle(randf() * TAU) * randf_range(8.0, 20.0)
		var t2: Tween = dot.create_tween()
		t2.tween_property(dot, "position", rdir, 0.15)
