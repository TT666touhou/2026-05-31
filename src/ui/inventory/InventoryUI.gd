extends Control
class_name InventoryUI

const SLOT_SIZE = 40
const GRID_COLS = 10
const GRID_ROWS = 4
const HOTBAR_SLOTS = 4

var mgr # Untyped to prevent parse errors

# Drag state
var dragging_item = null
var dragging_source_type: String = "" # "backpack" or "hotbar"
var dragging_source_index: int = -1 # Used if hotbar
var drag_offset_grid: Vector2i = Vector2i.ZERO

var backpack_rect: Rect2
var hotbar_rect: Rect2
var backpack_open: bool = false

signal item_dropped_outside(item_data: ItemData, global_mouse_pos: Vector2)

func _ready() -> void:
	custom_minimum_size = Vector2(1280, 720) # Assume 720p roughly
	mouse_filter = Control.MOUSE_FILTER_IGNORE # Let children or specific rects catch it
	
	backpack_rect = Rect2(Vector2(440, 200), Vector2(GRID_COLS * SLOT_SIZE, GRID_ROWS * SLOT_SIZE))
	hotbar_rect = Rect2(Vector2(640 - (HOTBAR_SLOTS * SLOT_SIZE) / 2.0, 650), Vector2(HOTBAR_SLOTS * SLOT_SIZE, SLOT_SIZE))
	
	set_process_input(true)

func set_manager(manager) -> void:
	mgr = manager
	mgr.inventory_changed.connect(queue_redraw)
	queue_redraw()

func toggle_backpack() -> void:
	backpack_open = !backpack_open
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not visible or not mgr: return
	
	if event is InputEventMouseMotion:
		if dragging_item:
			queue_redraw()
			
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_mouse_down(event.position)
			else:
				_handle_mouse_up(event.position)

func _handle_mouse_down(pos: Vector2) -> void:
	# Check hotbar
	if hotbar_rect.has_point(pos):
		var local_x = pos.x - hotbar_rect.position.x
		var idx = int(local_x / SLOT_SIZE)
		if idx >= 0 and idx < HOTBAR_SLOTS and mgr.hotbar_items[idx] != null:
			dragging_item = mgr.hotbar_items[idx]
			dragging_source_type = "hotbar"
			dragging_source_index = idx
			drag_offset_grid = Vector2i.ZERO
			mgr.hotbar_items[idx] = null
			queue_redraw()
			return
			
	# Check backpack
	if backpack_open and backpack_rect.has_point(pos):
		var local_pos = pos - backpack_rect.position
		var grid_pos = Vector2i(int(local_pos.x / SLOT_SIZE), int(local_pos.y / SLOT_SIZE))
		# Find if an item is under this grid_pos
		for item in mgr.backpack_items:
			var rect = Rect2i(item.grid_pos, item.data.grid_size)
			if rect.has_point(grid_pos):
				dragging_item = item
				dragging_source_type = "backpack"
				drag_offset_grid = grid_pos - item.grid_pos
				mgr.backpack_items.erase(item)
				queue_redraw()
				return

func _handle_mouse_up(pos: Vector2) -> void:
	if not dragging_item: return
	
	var drop_handled = false
	
	# Try hotbar
	if hotbar_rect.has_point(pos):
		var local_x = pos.x - hotbar_rect.position.x
		var idx = int(local_x / SLOT_SIZE)
		if idx >= 0 and idx < HOTBAR_SLOTS:
			if mgr.hotbar_items[idx] == null:
				mgr.hotbar_items[idx] = dragging_item
				drop_handled = true
			else:
				# Swap
				var temp = mgr.hotbar_items[idx]
				mgr.hotbar_items[idx] = dragging_item
				_return_item_to_source(temp)
				drop_handled = true
				
	# Try backpack
	if not drop_handled and backpack_open and backpack_rect.has_point(pos):
		var local_pos = pos - backpack_rect.position
		var grid_pos = Vector2i(int(local_pos.x / SLOT_SIZE), int(local_pos.y / SLOT_SIZE))
		var target_pos = grid_pos - drag_offset_grid
		if mgr.can_place_in_backpack(dragging_item.data, target_pos):
			dragging_item.grid_pos = target_pos
			mgr.backpack_items.append(dragging_item)
			drop_handled = true
			
	if not drop_handled:
		# Dropped outside!
		item_dropped_outside.emit(dragging_item.data, get_global_mouse_position())
		
	dragging_item = null
	mgr.inventory_changed.emit()

func _return_item_to_source(item) -> void:
	# Simple fallback if swap fails or whatever
	if not mgr.auto_add_to_backpack(item.data):
		item_dropped_outside.emit(item.data, get_global_mouse_position())

func _draw() -> void:
	# Draw Backpack
	if backpack_open:
		draw_rect(backpack_rect, Color(0, 0, 0, 0.7))
		for y in range(GRID_ROWS):
			for x in range(GRID_COLS):
				var r = Rect2(backpack_rect.position + Vector2(x * SLOT_SIZE, y * SLOT_SIZE), Vector2(SLOT_SIZE, SLOT_SIZE))
				draw_rect(r, Color.WHITE, false, 1.0)
			
	# Draw Hotbar
	draw_rect(hotbar_rect, Color(0, 0, 0, 0.7))
	for i in range(HOTBAR_SLOTS):
		var r = Rect2(hotbar_rect.position + Vector2(i * SLOT_SIZE, 0), Vector2(SLOT_SIZE, SLOT_SIZE))
		draw_rect(r, Color.WHITE, false, 1.0)
		
	if not mgr: return
	
	# Draw Items in Backpack
	if backpack_open:
		for item in mgr.backpack_items:
			var pos = backpack_rect.position + Vector2(item.grid_pos) * SLOT_SIZE
			var item_size = Vector2(item.data.grid_size) * SLOT_SIZE
			_draw_item(item.data, pos, item_size)
		
	# Draw Items in Hotbar
	for i in range(HOTBAR_SLOTS):
		if mgr.hotbar_items[i]:
			var pos = hotbar_rect.position + Vector2(i * SLOT_SIZE, 0)
			_draw_item(mgr.hotbar_items[i].data, pos, Vector2(SLOT_SIZE, SLOT_SIZE))
			
	# Draw Dragging Item
	if dragging_item:
		var mpos = get_local_mouse_position()
		var item_size = Vector2(dragging_item.data.grid_size) * SLOT_SIZE
		var draw_pos = mpos - Vector2(drag_offset_grid) * SLOT_SIZE - Vector2(SLOT_SIZE / 2.0, SLOT_SIZE / 2.0)
		_draw_item(dragging_item.data, draw_pos, item_size)

func _draw_item(data, pos: Vector2, item_size: Vector2) -> void:
	# Draw background fill
	draw_rect(Rect2(pos, item_size), Color(0.2, 0.2, 0.2, 0.8))
	draw_rect(Rect2(pos, item_size), Color.WHITE, false, 2.0)
	
	var center = pos + item_size / 2.0
	# Draw lines
	for lines in data.icon_lines:
		var transformed_lines = PackedVector2Array()
		for pt in lines:
			# pt is -0.5 to 0.5 relative to the grid size
			var abs_pt = center + Vector2(pt.x * item_size.x, pt.y * item_size.y)
			transformed_lines.append(abs_pt)
		if transformed_lines.size() >= 2:
			draw_polyline(transformed_lines, Color.WHITE, 2.0)
