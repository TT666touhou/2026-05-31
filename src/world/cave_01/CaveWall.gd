@tool
extends StaticBody2D
class_name CaveWall

@export var color: Color = Color(0.1, 0.08, 0.05, 1.0) # 內部填色
@export var outline_color: Color = Color.WHITE
@export var outline_width: float = 2.0

var collision_poly: CollisionPolygon2D
var visual_poly: Polygon2D
var visual_line: Line2D

func _ready() -> void:
	collision_poly = get_node_or_null("CollisionPolygon2D")
	if not collision_poly: return
	
	visual_poly = Polygon2D.new()
	visual_poly.color = color
	add_child(visual_poly)
	
	visual_line = Line2D.new()
	visual_line.default_color = outline_color
	visual_line.width = outline_width
	visual_line.closed = true
	add_child(visual_line)
	
	_update_visuals()
	
	if Engine.is_editor_hint():
		set_process(true)
	else:
		set_process(false)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_update_visuals()

func _update_visuals() -> void:
	if collision_poly and visual_poly and visual_line:
		var pts = collision_poly.polygon
		visual_poly.polygon = pts
		visual_line.points = pts
