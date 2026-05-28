## class_name HitboxComponent
## Damage source. Attach to weapons/attacks. Activates during attack frames.
## Set collision layer to match PlayerAttack (6) or EnemyAttack (7).
class_name HitboxComponent
extends Area2D

# ─── Exports ────────────────────────────────────────────────────────────────
@export var damage: float = 10.0
@export var knockback_force: float = 200.0
var knockback_direction_override: Vector2 = Vector2.ZERO

# ─── Signals ────────────────────────────────────────────────────────────────
signal hit_landed(target: Node2D)

# ─── State ──────────────────────────────────────────────────────────────────
var _active: bool = false
var hit_targets: Array = []

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
	hit_targets.clear()

func is_active() -> bool:
	return _active

func _physics_process(_delta: float) -> void:
	if not _active or not monitoring:
		return
		
	var current_overlapping = []
	for area in get_overlapping_areas():
		if area is HurtboxComponent:
			var target = area.get_parent()
			current_overlapping.append(target)
			
			if not hit_targets.has(target):
				hit_targets.append(target)
				
				
				var kb_dir = knockback_direction_override
				if kb_dir == Vector2.ZERO:
					kb_dir = (area.global_position - global_position).normalized()
					
				var final_knockback = kb_dir * knockback_force
				
				# Deal damage
				area.receive_hit(damage, final_knockback)
				hit_landed.emit(target)
				
				# Trigger Combat Juice!
				if CombatFX:
					CombatFX.apply_hitstop()
					var hit_dir = (area.global_position - global_position).normalized()
					CombatFX.spawn_hit_spark(global_position + hit_dir * 10.0, hit_dir)
					
	# Clean up hit_targets so we can hit them again if they leave and re-enter
	for target in hit_targets.duplicate():
		if not current_overlapping.has(target):
			hit_targets.erase(target)
