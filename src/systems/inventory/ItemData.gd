extends Resource
class_name ItemData

@export var id: String = ""
@export var item_name: String = "Unknown Item"
@export var grid_size: Vector2i = Vector2i(1, 1)

# 對應的武器場景 (例如 res://src/items/weapons/sword.tscn)
@export var weapon_scene: PackedScene

# 白線條風格繪圖用的線段 (相對於 1x1 網格的正規化座標 -0.5 到 0.5)
# 若留空，UI 會預設畫一個打叉的框框
@export var icon_lines: Array[PackedVector2Array] = []

