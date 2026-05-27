## class_name HurtboxComponent
## Damage receiver. Attach to entities that can take damage.
## Connects to HealthComponent on same parent or via exported NodePath.
class_name HurtboxComponent
extends Area2D

# ─── Exports ────────────────────────────────────────────────────────────────
@export var health_component_path: NodePath = NodePath("../HealthComponent")

# ─── Signals ────────────────────────────────────────────────────────────────
signal hit_received(damage: float, knockback: Vector2)

# ─── State ──────────────────────────────────────────────────────────────────
var _health_component: HealthComponent = null

# ─── Lifecycle ──────────────────────────────────────────────────────────────
func _ready() -> void:
	monitorable = true
	monitoring = false  # Hurtbox doesn't need to detect anything itself
	_health_component = get_node_or_null(health_component_path) as HealthComponent

# ─── Public API (called by HitboxComponent) ──────────────────────────────────
func receive_hit(damage: float, knockback_force: float, from_position: Vector2) -> void:
	var knockback_direction: Vector2 = (global_position - from_position).normalized()
	var knockback: Vector2 = knockback_direction * knockback_force
	hit_received.emit(damage, knockback)
	if _health_component:
		_health_component.take_damage(damage)
