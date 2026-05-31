extends SceneTree

func _init():
	var floor_layer = TileMapLayer.new()
	var wall_layer = TileMapLayer.new()
	
	var floor_cells = {}
	# West Room
	for x in range(-25, 26):
		for y in range(-18, 19):
			floor_cells[Vector2i(x, y)] = true
	# East Room
	for x in range(26, 63):
		for y in range(-12, 13):
			floor_cells[Vector2i(x, y)] = true
	# Corridor
	for x in range(25, 27):
		for y in range(-1, 2):
			floor_cells[Vector2i(x, y)] = true
			
	var wall_cells = {}
	for cell in floor_cells.keys():
		# Use posmod to map world coordinates to atlas coordinates (16x16 tiles).
		# This ensures the 256x256 image tiles seamlessly across the level, preserving color transitions.
		var atlas_x = posmod(cell.x, 16)
		var atlas_y = posmod(cell.y, 16)
		floor_layer.set_cell(cell, 1, Vector2i(atlas_x, atlas_y))
		
		# Detect walls
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var n = cell + Vector2i(dx, dy)
				if not floor_cells.has(n):
					wall_cells[n] = true
					
	for cell in wall_cells.keys():
		wall_layer.set_cell(cell, 2, Vector2i(randi() % 16, randi() % 4))
		
	var out_file = FileAccess.open("res://layout_data.json", FileAccess.WRITE)
	var data = {
		"floor": Marshalls.raw_to_base64(floor_layer.tile_map_data),
		"wall": Marshalls.raw_to_base64(wall_layer.tile_map_data)
	}
	out_file.store_string(JSON.stringify(data))
	out_file.close()
	print("Data saved to layout_data.json")
	quit()
