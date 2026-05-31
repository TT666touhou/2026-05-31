# PropFurniture.gd
# 程序繪製的家具掩體 (衣櫃/箱子/桌子)
# 作為 RigidBody2D 可以被推動，並內建 LightOccluder2D 遮擋視線與光影

class_name PropFurniture
extends RigidBody2D

enum PropType {
	CRATE,      # 箱子 (正方形)
	WARDROBE,   # 衣櫃 (長方形)
	TABLE       # 桌子 (長方形，空心感)
}

@export var type: PropType = PropType.CRATE
@export var size: Vector2 = Vector2(48.0, 48.0)
@export var wood_color: Color = Color(0.26, 0.20, 0.16, 1.0)      # 腐木褐色
@export var border_color: Color = Color(0.14, 0.11, 0.09, 1.0)
@export var inner_dark: Color = Color(0.06, 0.05, 0.04, 1.0)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var occluder: LightOccluder2D = $LightOccluder2D

func _ready() -> void:
	# 設定剛體屬性：低摩阻、高質量，推起來有重量感
	mass = 3.0
	gravity_scale = 0.0
	linear_damp = 8.0
	angular_damp = 8.0
	
	# 設定 Light Mask: 4 (第三層 家具層)，使其不接收自身陰影，但仍能被照亮
	light_mask = 4
	
	# 設定碰撞層 (layer 256: Props, mask 1: World, 2: Player, 4: Enemy, 256: Props)
	collision_layer = 256
	collision_mask = 1 | 2 | 4 | 256
	
	# 更新碰撞盒大小
	if collision_shape and collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = size
		
	# 更新光線遮擋體
	_setup_occluder()
	queue_redraw()

func setup(p_type: PropType, p_size: Vector2) -> void:
	type = p_type
	size = p_size
	
	# 根據類型微調物理重量
	match type:
		PropType.CRATE: mass = 3.0
		PropType.WARDROBE: mass = 6.0
		PropType.TABLE: mass = 2.0
		
	if is_inside_tree():
		if collision_shape and collision_shape.shape is RectangleShape2D:
			collision_shape.shape.size = size
		_setup_occluder()
		queue_redraw()

func _setup_occluder() -> void:
	if occluder == null:
		return
	var poly = OccluderPolygon2D.new()
	poly.closed = true
	var hx = size.x / 2.0
	var hy = size.y / 2.0
	# 稍微往內縮 1 像素，防止與碰撞盒摩擦卡死光影
	hx = maxf(1.0, hx - 1.0)
	hy = maxf(1.0, hy - 1.0)
	poly.polygon = PackedVector2Array([
		Vector2(-hx, -hy),
		Vector2(hx, -hy),
		Vector2(hx, hy),
		Vector2(-hx, hy)
	])
	occluder.occluder = poly
	# 讓遮擋體在第 1 層 (地板) 與第 2 層 (角色) 投影陰影，但不在第 3 層 (自身) 投影
	occluder.occluder_light_mask = 3

func _draw() -> void:
	var hx = size.x / 2.0
	var hy = size.y / 2.0
	var rect = Rect2(-hx, -hy, size.x, size.y)
	
	# ── 繪製本體底色 ──
	draw_rect(rect, wood_color, true)
	
	# ── 繪製邊框 ──
	draw_rect(rect, border_color, false, 2.0)
	
	# ── 繪製內部細節與環境光遮蔽 (AO) 漸層 ──
	match type:
		PropType.CRATE:
			# 畫對角交叉木條
			draw_line(Vector2(-hx, -hy), Vector2(hx, hy), border_color, 2.0)
			draw_line(Vector2(hx, -hy), Vector2(-hx, hy), border_color, 2.0)
			
			# 箱子邊緣內縮暗圈 (AO)
			draw_rect(Rect2(-hx + 3, -hy + 3, size.x - 6, size.y - 6), Color(0, 0, 0, 0.25), false, 2.0)
			
		PropType.WARDROBE:
			# 衣櫃中縫線
			draw_line(Vector2(0, -hy), Vector2(0, hy), border_color, 2.0)
			# 兩扇門的把手
			draw_circle(Vector2(-4, 0), 2.5, border_color)
			draw_circle(Vector2(4, 0), 2.5, border_color)
			
			# 衣櫃頂部受光面與內部暗區
			draw_rect(Rect2(-hx + 2, -hy + 2, size.x - 4, 4), wood_color.lightened(0.15), true)
			draw_rect(Rect2(-hx + 2, -hy + 6, size.x - 4, size.y - 8), inner_dark.darkened(0.2), false, 2.0)
			
		PropType.TABLE:
			# 桌子頂部畫四邊收縮的木紋框
			draw_rect(Rect2(-hx + 4, -hy + 4, size.x - 8, size.y - 8), border_color, false, 1.5)
			# 桌子中心紋理
			draw_line(Vector2(-hx + 10, 0), Vector2(hx - 10, 0), border_color, 1.5)
