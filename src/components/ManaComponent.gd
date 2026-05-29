## class_name ManaComponent
## Manages mana resources for casting spells.
class_name ManaComponent
extends Node

# ─── Exports ────────────────────────────────────────────────────────────────
@export var max_mana: float = 100.0
@export var regen_rate: float = 0.0  ## Mana recovered per second (0 by default in souls-like)
@export var regen_delay: float = 0.0

# ─── Signals ────────────────────────────────────────────────────────────────
signal mana_changed(old_val: float, new_val: float)
signal mana_depleted()

# ─── State ──────────────────────────────────────────────────────────────────
var current_mana: float = 0.0
var _regen_timer: float = 0.0

# ─── Lifecycle ──────────────────────────────────────────────────────────────
func _ready() -> void:
	current_mana = max_mana

func _process(delta: float) -> void:
	if regen_rate <= 0.0:
		return
		
	if _regen_timer > 0.0:
		_regen_timer -= delta
	elif current_mana < max_mana:
		var old_val: float = current_mana
		current_mana = minf(max_mana, current_mana + regen_rate * delta)
		if current_mana != old_val:
			mana_changed.emit(old_val, current_mana)

# ─── Public API ─────────────────────────────────────────────────────────────
func has_enough(amount: float) -> bool:
	return current_mana >= amount

func consume(amount: float) -> bool:
	if not has_enough(amount):
		mana_depleted.emit()
		return false
		
	var old_val: float = current_mana
	current_mana -= amount
	_regen_timer = regen_delay
	
	mana_changed.emit(old_val, current_mana)
	
	if current_mana <= 0.0:
		mana_depleted.emit()
		
	return true

func restore(amount: float) -> void:
	var old_val: float = current_mana
	current_mana = minf(max_mana, current_mana + amount)
	if old_val != current_mana:
		mana_changed.emit(old_val, current_mana)

func get_mana_percent() -> float:
	if max_mana <= 0.0:
		return 0.0
	return current_mana / max_mana
