## class_name WallSegment
## Straight rectangular wall piece. Adjust wall_length and wall_thickness in the Inspector.
## Drag-and-drop from FileSystem. Rotate freely in the editor.
@tool
class_name WallSegment
extends TerrainPiece

# ─── Exports ────────────────────────────────────────────────────────────────
@export var wall_length: float = 128.0:
	set(v):
		wall_length = maxf(8.0, v)
		_rebuild()

@export var wall_thickness: float = 32.0:
	set(v):
		wall_thickness = maxf(8.0, v)
		_rebuild()

# ─── Shape Definition ────────────────────────────────────────────────────────
func _get_polygon_points() -> PackedVector2Array:
	var hw: float = wall_length * 0.5
	var ht: float = wall_thickness * 0.5
	return PackedVector2Array([
		Vector2(-hw, -ht),
		Vector2( hw, -ht),
		Vector2( hw,  ht),
		Vector2(-hw,  ht),
	])
