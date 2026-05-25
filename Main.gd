extends Node2D

@onready var cam = $TrackingCamera
@onready var terrain = $Terrain
@onready var player = $Player

func _ready():
	if not terrain or not cam: return
	
	cam.make_current()
	
	if player:
		pass

	
	var cell_size = Vector2(16, 16)
	if terrain.tile_set:
		cell_size = Vector2(terrain.tile_set.tile_size)
		
	var min_x = 0
	var min_y = 0
	var max_x = 100
	var max_y = 50
	
	if terrain.has_method("get_used_rect"):
		var rect = terrain.get_used_rect()
		min_x = rect.position.x
		min_y = rect.position.y
		max_x = rect.position.x + rect.size.x
		max_y = rect.position.y + rect.size.y
	elif terrain.has_method("get_used_cells"):
		var cells = terrain.get_used_cells(0)
		if cells.size() > 0:
			min_x = cells[0].x
			min_y = cells[0].y
			max_x = cells[0].x
			max_y = cells[0].y
			for cell in cells:
				if cell.x < min_x: min_x = cell.x
				if cell.x > max_x: max_x = cell.x
				if cell.y < min_y: min_y = cell.y
				if cell.y > max_y: max_y = cell.y
			max_x += 1
			max_y += 1
			
	var limit_left = (min_x * cell_size.x) + terrain.global_position.x
	var limit_top = (min_y * cell_size.y) + terrain.global_position.y
	var limit_right = (max_x * cell_size.x) + terrain.global_position.x
	var limit_bottom = (max_y * cell_size.y) + terrain.global_position.y
	
	cam.limit_left = int(limit_left)
	cam.limit_top = int(limit_top) - 300
	cam.limit_right = int(limit_right)
	cam.limit_bottom = int(limit_bottom)
	
	# 置中鏡頭，不跟隨玩家
	# 寬度剛好對齊場景寬度，下方切齊 tile 邊緣
	cam.zoom = Vector2.ONE
	
	var vp_size = get_viewport_rect().size
	var cam_x = (limit_left + limit_right) / 2.0
	var cam_y = limit_bottom - (vp_size.y / 2.0)
	
	cam.global_position = Vector2(cam_x, cam_y)
