## class_name CaveChunk
## Free-form irregular terrain piece for organic cave walls.
## Draw the shape using Godot's built-in Polygon2D editor (select Polygon2D child, use the vertex tool).
## The script auto-syncs CollisionPolygon2D and LightOccluder2D whenever you modify the polygon.
@tool
class_name CaveChunk
extends StaticBody2D

# ─── Exports ────────────────────────────────────────────────────────────────
@export var fill_color: Color = Color("#7A5C10"):
	set(v):
		fill_color = v
		_sync_visual()

@export var outline_color: Color = Color("#22CC22"):
	set(v):
		outline_color = v
		queue_redraw()

@export var outline_width: float = 3.0:
	set(v):
		outline_width = v
		queue_redraw()

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

# ─── State ──────────────────────────────────────────────────────────────────
var _last_polygon: PackedVector2Array

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_sync_all()

func _process(_delta: float) -> void:
	# In editor mode: monitor the Polygon2D for manual edits by the designer
	if Engine.is_editor_hint():
		var poly2d: Polygon2D = get_node_or_null("Polygon2D")
		if poly2d and poly2d.polygon != _last_polygon:
			_last_polygon = poly2d.polygon.duplicate()
			_sync_from_polygon2d()

func _draw() -> void:
	var poly2d: Polygon2D = get_node_or_null("Polygon2D")
	if not poly2d:
		return
	var pts: PackedVector2Array = poly2d.polygon
	if pts.size() < 3:
		return

	if show_dot_texture:
		_draw_dot_texture(pts)

	if outline_width > 0.0:
		var closed_pts: PackedVector2Array = pts.duplicate()
		closed_pts.append(pts[0])
		draw_polyline(closed_pts, outline_color, outline_width, true)

# ─── Internal Sync ───────────────────────────────────────────────────────────
func _sync_from_polygon2d() -> void:
	var poly2d: Polygon2D = get_node_or_null("Polygon2D")
	if not poly2d:
		return
	var pts: PackedVector2Array = poly2d.polygon

	var col_poly: CollisionPolygon2D = get_node_or_null("CollisionPolygon2D")
	if col_poly:
		col_poly.polygon = pts

	var occ: LightOccluder2D = get_node_or_null("LightOccluder2D")
	if occ and occ.occluder:
		occ.occluder.polygon = pts

	queue_redraw()

func _sync_visual() -> void:
	var poly2d: Polygon2D = get_node_or_null("Polygon2D")
	if poly2d:
		poly2d.color = fill_color

func _sync_all() -> void:
	_sync_visual()
	_sync_from_polygon2d()

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
