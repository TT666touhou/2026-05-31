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
var hit_cooldowns: Dictionary = {}
@export var cooldown_time: float = 0.5

func _ready() -> void:
	if not _active:
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

func _physics_process(_delta: float) -> void:
	if not _active or not monitoring:
		return
		
	for area in get_overlapping_areas():
		if area is HurtboxComponent:
			var hurtbox: HurtboxComponent = area as HurtboxComponent
			var target = hurtbox.get_parent()
			
			var current_time = Time.get_ticks_msec() / 1000.0
			if hit_cooldowns.has(target) and current_time - hit_cooldowns[target] < cooldown_time:
				continue
				
			hit_cooldowns[target] = current_time
			hurtbox.receive_hit(damage, knockback_force, global_position)
			hit_landed.emit(target)
