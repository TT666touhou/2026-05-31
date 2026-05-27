## class_name WallCorner
## 90-degree corner piece. Comes in outer (convex) or inner (concave/L-shape) variants.
## Use corner_type to switch between them.
@tool
class_name WallCorner
extends TerrainPiece

enum CornerType { OUTER_90, INNER_90 }

# ─── Exports ────────────────────────────────────────────────────────────────
@export var corner_size: float = 32.0:
	set(v):
		corner_size = maxf(8.0, v)
		_rebuild()

@export var thickness: float = 32.0:
	set(v):
		thickness = maxf(8.0, v)
		_rebuild()

@export var corner_type: CornerType = CornerType.OUTER_90:
	set(v):
		corner_type = v
		_rebuild()

# ─── Shape Definition ────────────────────────────────────────────────────────
func _get_polygon_points() -> PackedVector2Array:
	var s: float = corner_size
	var t: float = thickness
	match corner_type:
		CornerType.OUTER_90:
			# Simple filled square corner block
			return PackedVector2Array([
				Vector2(0, 0),
				Vector2(s, 0),
				Vector2(s, s),
				Vector2(0, s),
			])
		CornerType.INNER_90:
			# L-shaped corner (two walls meeting, leaving a walkable gap)
			# Outer L: fills two sides of a square, leaving the inner corner open
			return PackedVector2Array([
				Vector2(0,   0),
				Vector2(s,   0),
				Vector2(s,   t),
				Vector2(t,   t),
				Vector2(t,   s),
				Vector2(0,   s),
			])
	return PackedVector2Array()
