## class_name StaminaComponent
## Manages stamina, consumption, and regeneration.
class_name StaminaComponent
extends Node

# ─── Exports ────────────────────────────────────────────────────────────────
@export var max_stamina: float = 100.0
@export var regen_rate: float = 30.0  ## Stamina recovered per second
@export var regen_delay: float = 1.0  ## Seconds to wait before regen starts after consumption

# ─── Signals ────────────────────────────────────────────────────────────────
signal stamina_changed(old_val: float, new_val: float)
signal stamina_depleted()

# ─── State ──────────────────────────────────────────────────────────────────
var current_stamina: float = 0.0
var _regen_timer: float = 0.0

# ─── Lifecycle ──────────────────────────────────────────────────────────────
func _ready() -> void:
	current_stamina = max_stamina

func _process(delta: float) -> void:
	if _regen_timer > 0.0:
		_regen_timer -= delta
	elif current_stamina < max_stamina:
		var old_val: float = current_stamina
		current_stamina = minf(max_stamina, current_stamina + regen_rate * delta)
		if current_stamina != old_val:
			stamina_changed.emit(old_val, current_stamina)

# ─── Public API ─────────────────────────────────────────────────────────────
func has_enough(amount: float) -> bool:
	return current_stamina >= amount

func consume(amount: float) -> bool:
	if not has_enough(amount):
		stamina_depleted.emit()
		return false
		
	var old_val: float = current_stamina
	current_stamina -= amount
	_regen_timer = regen_delay # Reset regen delay
	
	stamina_changed.emit(old_val, current_stamina)
	
	if current_stamina <= 0.0:
		stamina_depleted.emit()
		
	return true

func restore(amount: float) -> void:
	var old_val: float = current_stamina
	current_stamina = minf(max_stamina, current_stamina + amount)
	if old_val != current_stamina:
		stamina_changed.emit(old_val, current_stamina)

func get_stamina_percent() -> float:
	if max_stamina <= 0.0:
		return 0.0
	return current_stamina / max_stamina
