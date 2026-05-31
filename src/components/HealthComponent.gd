## class_name HealthComponent
## Manages health, invincibility frames, and death signalling for any entity.
## Attach as a child node. Connect 'health_changed' and 'died' signals.
class_name HealthComponent
extends Node

# ─── Exports ────────────────────────────────────────────────────────────────
@export var max_health: float = 100.0
@export var invincibility_duration: float = 0.5  ## Seconds of invincibility after taking damage

# ─── Signals ────────────────────────────────────────────────────────────────
signal health_changed(old_val: float, new_val: float)
signal died()

# ─── State ──────────────────────────────────────────────────────────────────
var current_health: float = 0.0
var _is_dead: bool = false
var _is_invincible: bool = false
var _invincibility_timer: float = 0.0

# ─── Lifecycle ──────────────────────────────────────────────────────────────
func _ready() -> void:
	current_health = max_health

func _process(delta: float) -> void:
	if _is_invincible:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_is_invincible = false

# ─── Public API ─────────────────────────────────────────────────────────────
func take_damage(amount: float) -> void:
	if _is_dead or _is_invincible:
		return
	var old_val: float = current_health
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(old_val, current_health)
	_start_invincibility()
	if current_health <= 0.0:
		_die()

func heal(amount: float) -> void:
	if _is_dead:
		return
	var old_val: float = current_health
	current_health = minf(max_health, current_health + amount)
	if old_val != current_health:
		health_changed.emit(old_val, current_health)

func get_health_percent() -> float:
	if max_health <= 0.0:
		return 0.0
	return current_health / max_health

func is_dead() -> bool:
	return _is_dead

func is_invincible() -> bool:
	return _is_invincible

# ─── Private ─────────────────────────────────────────────────────────────────
func _start_invincibility() -> void:
	if invincibility_duration > 0.0:
		_is_invincible = true
		_invincibility_timer = invincibility_duration

func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	died.emit()
