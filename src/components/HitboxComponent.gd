## class_name HitboxComponent
## Damage source. Attach to weapons/attacks. Activates during attack frames.
## Set collision layer to match PlayerAttack (6) or EnemyAttack (7).
class_name HitboxComponent
extends Area2D

# ─── Exports ────────────────────────────────────────────────────────────────
@export var damage: float = 10.0
@export var knockback_force: float = 200.0

# ─── Signals ────────────────────────────────────────────────────────────────
signal hit_landed(target: Node2D)

# ─── State ──────────────────────────────────────────────────────────────────
var _active: bool = false

# ─── Lifecycle ──────────────────────────────────────────────────────────────
func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitoring = false  # Off by default; enable during attack frames

# ─── Public API ─────────────────────────────────────────────────────────────
func activate() -> void:
	monitoring = true
	_active = true

func deactivate() -> void:
	monitoring = false
	_active = false

func is_active() -> bool:
	return _active

# ─── Private ─────────────────────────────────────────────────────────────────
func _on_area_entered(area: Area2D) -> void:
	if not _active:
		return
	if area is HurtboxComponent:
		var hurtbox: HurtboxComponent = area as HurtboxComponent
		hurtbox.receive_hit(damage, knockback_force, global_position)
		hit_landed.emit(area.get_parent())
