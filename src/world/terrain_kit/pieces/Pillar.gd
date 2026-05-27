## class_name Pillar
## Square pillar obstacle. Blocks movement AND vision (has LightOccluder2D).
## Good for adding visual interest and tactical cover to dungeon rooms.
@tool
class_name Pillar
extends TerrainPiece

# ─── Exports ────────────────────────────────────────────────────────────────
@export var pillar_size: float = 28.0:
	set(v):
		pillar_size = maxf(8.0, v)
		_rebuild()

@export var chamfer: float = 4.0:
	set(v):
		chamfer = clampf(v, 0.0, pillar_size * 0.3)
		_rebuild()

# ─── Shape Definition ────────────────────────────────────────────────────────
func _get_polygon_points() -> PackedVector2Array:
	var h: float = pillar_size * 0.5
	var c: float = chamfer
	if c <= 0.0:
		# Simple square
		return PackedVector2Array([
			Vector2(-h, -h), Vector2(h, -h),
			Vector2(h, h),   Vector2(-h, h),
		])
	else:
		# Chamfered square (cut corners for a more stone-like look)
		return PackedVector2Array([
			Vector2(-h + c, -h),
			Vector2( h - c, -h),
			Vector2( h,     -h + c),
			Vector2( h,      h - c),
			Vector2( h - c,  h),
			Vector2(-h + c,  h),
			Vector2(-h,      h - c),
			Vector2(-h,     -h + c),
		])
