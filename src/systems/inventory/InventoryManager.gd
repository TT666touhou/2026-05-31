extends Node
class_name InventoryManager

const GRID_W = 10
const GRID_H = 4
const HOTBAR_SIZE = 4

class InventoryItem:
	var data: ItemData
	var grid_pos: Vector2i = Vector2i(-1, -1)
	
	func _init(p_data: ItemData):
		data = p_data

# 背包內的物品
var backpack_items: Array[InventoryItem] = []

# 快捷列的物品 (長度固定為 HOTBAR_SIZE，空位為 null)
var hotbar_items: Array[InventoryItem] = []

signal inventory_changed

func _ready() -> void:
	hotbar_items.resize(HOTBAR_SIZE)
	for i in range(HOTBAR_SIZE):
		hotbar_items[i] = null

# === 背包邏輯 (Grid) ===

func can_place_in_backpack(item_data: ItemData, pos: Vector2i, ignore_item: InventoryItem = null) -> bool:
	if pos.x < 0 or pos.y < 0: return false
	if pos.x + item_data.grid_size.x > GRID_W: return false
	if pos.y + item_data.grid_size.y > GRID_H: return false
	
	var item_rect = Rect2i(pos, item_data.grid_size)
	
	for other in backpack_items:
		if other == ignore_item:
			continue
		var other_rect = Rect2i(other.grid_pos, other.data.grid_size)
		if item_rect.intersects(other_rect):
			return false
			
	return true

func add_to_backpack(item_data: ItemData, pos: Vector2i) -> bool:
	if can_place_in_backpack(item_data, pos):
		var item = InventoryItem.new(item_data)
		item.grid_pos = pos
		backpack_items.append(item)
		inventory_changed.emit()
		return true
	return false

func auto_add_to_backpack(item_data: ItemData) -> bool:
	for y in range(GRID_H):
		for x in range(GRID_W):
			if add_to_backpack(item_data, Vector2i(x, y)):
				return true
	return false

func remove_from_backpack(item: InventoryItem) -> void:
	if item in backpack_items:
		backpack_items.erase(item)
		inventory_changed.emit()

# === 快捷列邏輯 (Hotbar) ===

func set_hotbar_item(index: int, item_data: ItemData) -> InventoryItem:
	if index < 0 or index >= HOTBAR_SIZE: return null
	var item = null
	if item_data != null:
		item = InventoryItem.new(item_data)
	hotbar_items[index] = item
	inventory_changed.emit()
	return item

func remove_from_hotbar(index: int) -> void:
	if index >= 0 and index < HOTBAR_SIZE:
		hotbar_items[index] = null
		inventory_changed.emit()

func clear() -> void:
	backpack_items.clear()
	for i in range(HOTBAR_SIZE):
		hotbar_items[i] = null
	inventory_changed.emit()
