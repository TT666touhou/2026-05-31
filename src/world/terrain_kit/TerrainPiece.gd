## Base class for all modular dungeon terrain pieces.
## Subclasses override _get_polygon_points() to define shape.
## Any @export change automatically syncs Polygon2D + CollisionPolygon2D + LightOccluder2D.
@tool
class_name TerrainPiece
extends StaticBody2D

# ─── Visual Exports ──────────────────────────────────────────────────────────
@export var fill_color: Color = Color("#7A5C10"):
	set(v):
		fill_color = v
		_rebuild()

@export var outline_color: Color = Color("#22CC22"):
	set(v):
		outline_color = v
		_rebuild()

@export var outline_width: float = 3.0:
	set(v):
		outline_width = v
		_rebuild()

@export var show_dot_texture: bool = true:
	set(v):
		show_dot_texture = v
		queue_redraw()

@export var dot_spacing: float = 8.0:
	set(v):
		dot_spacing = maxf(4.0, v)
		queue_redraw()

@export var dot_color: Color = Color("#5C3D0A"):
	set(v):
		dot_color = v
		queue_redraw()

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_rebuild()

func _draw() -> void:
	# IMPORTANT: Fill is handled by the Polygon2D child node.
	# Do NOT call draw_colored_polygon() here — that causes double-render black fragments.
	var pts: PackedVector2Array = _get_polygon_points()
	if pts.size() < 3:
		return

	# Dots (drawn on top of Polygon2D fill)
	if show_dot_texture:
		_draw_dot_texture(pts)

	# Outline
	if outline_width > 0.0:
		var closed: PackedVector2Array = pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, outline_color, outline_width, true)

# ─── Protected: override in subclasses ───────────────────────────────────────
func _get_polygon_points() -> PackedVector2Array:
	return PackedVector2Array()

# ─── Internal ────────────────────────────────────────────────────────────────
func _rebuild() -> void:
	if not is_inside_tree():
		return
	var pts: PackedVector2Array = _get_polygon_points()
	if pts.size() < 3:
		return

	# Sync Polygon2D (handles the filled visual)
	var poly2d: Polygon2D = get_node_or_null("Polygon2D")
	if poly2d:
		poly2d.polygon = pts
		poly2d.color = fill_color

	# Sync CollisionPolygon2D
	var col_poly: CollisionPolygon2D = get_node_or_null("CollisionPolygon2D")
	if col_poly:
		col_poly.polygon = pts

	# Sync LightOccluder2D
	var occluder_node: LightOccluder2D = get_node_or_null("LightOccluder2D")
	if occluder_node and occluder_node.occluder:
		occluder_node.occluder.polygon = pts

	queue_redraw()

func _draw_dot_texture(pts: PackedVector2Array) -> void:
	var min_x: float = INF; var max_x: float = -INF
	var min_y: float = INF; var max_y: float = -INF
	for p: Vector2 in pts:
		min_x = minf(min_x, p.x); max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y); max_y = maxf(max_y, p.y)
	var x: float = min_x + dot_spacing
	while x < max_x:
		var y: float = min_y + dot_spacing
		while y < max_y:
			draw_circle(Vector2(x, y), 1.5, dot_color)
			y += dot_spacing
		x += dot_spacing
