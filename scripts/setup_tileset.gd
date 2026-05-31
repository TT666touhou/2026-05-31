extends SceneTree

func _init():
	print("Building TileSet...")
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(32, 32) # Base grid size
	
	# Add physics layer for walls
	tileset.add_physics_layer(0)
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 0)
	
	# Floor Source
	var floor_tex = load("res://assets/textures/floor_stone_a.png")
	if floor_tex:
		var floor_source = TileSetAtlasSource.new()
		floor_source.texture = floor_tex
		floor_source.texture_region_size = Vector2i(256, 256)
		floor_source.create_tile(Vector2i(0, 0))
		tileset.add_source(floor_source, 1)
		print("Added floor source")
	else:
		print("Failed to load floor texture")
		
	# Wall Source
	var wall_tex = load("res://assets/textures/wall_stone.png")
	if wall_tex:
		var wall_source = TileSetAtlasSource.new()
		wall_source.texture = wall_tex
		wall_source.texture_region_size = Vector2i(32, 32) # Slice the 256x64 into 32x32 tiles
		
		for x in range(8):
			for y in range(2):
				var coord = Vector2i(x, y)
				wall_source.create_tile(coord)
				# Add full collision box to each wall tile
				var poly = PackedVector2Array([
					Vector2(-16, -16), Vector2(16, -16),
					Vector2(16, 16), Vector2(-16, 16)
				])
				wall_source.tile_set_collision_polygons_count(coord, 0, 1)
				wall_source.tile_set_collision_polygon_points(coord, 0, 0, poly)
		tileset.add_source(wall_source, 2)
		print("Added wall source")
	else:
		print("Failed to load wall texture")
		
	ResourceSaver.save(tileset, "res://src/world/terrain_kit/DarkwoodTileSet.tres")
	print("Saved DarkwoodTileSet.tres")
	
	print("Rebuilding CaveLevel.tscn...")
	var cave_path = "res://src/world/cave_01/CaveLevel.tscn"
	var pack = load(cave_path)
	if pack and pack is PackedScene:
		var root = pack.instantiate()
		
		# Remove old nodes
		var to_remove = []
		for child in root.get_children():
			if "Wall" in child.name or "Floor" in child.name or "Segment" in child.name or "Door" in child.name or "Wood" in child.name or "Stone" in child.name:
				to_remove.append(child)
				
		for child in to_remove:
			root.remove_child(child)
			child.queue_free()
			
		# Add new TileMapLayers
		var floor_layer = TileMapLayer.new()
		floor_layer.name = "FloorLayer"
		floor_layer.tile_set = tileset
		floor_layer.z_index = -10
		# Quick fill some floor
		for x in range(-10, 10):
			for y in range(-10, 10):
				# floor_source ID is 1, tile is (0,0) -> wait, floor tile size is 256x256, but tileset base is 32x32.
				# A 256x256 tile takes up 8x8 cells. We place it every 8 cells.
				if x % 8 == 0 and y % 8 == 0:
					floor_layer.set_cell(Vector2i(x, y), 1, Vector2i(0, 0))
		root.add_child(floor_layer)
		floor_layer.owner = root
		
		var wall_layer = TileMapLayer.new()
		wall_layer.name = "WallLayer"
		wall_layer.tile_set = tileset
		# Quick wall boundary
		for x in range(-10, 10):
			wall_layer.set_cell(Vector2i(x, -10), 2, Vector2i(0, 0))
			wall_layer.set_cell(Vector2i(x, 9), 2, Vector2i(0, 0))
		for y in range(-9, 9):
			wall_layer.set_cell(Vector2i(-10, y), 2, Vector2i(0, 0))
			wall_layer.set_cell(Vector2i(9, y), 2, Vector2i(0, 0))
		root.add_child(wall_layer)
		wall_layer.owner = root
		
		var props_layer = Node2D.new()
		props_layer.name = "PropsLayer"
		props_layer.y_sort_enabled = true
		root.add_child(props_layer)
		props_layer.owner = root
		
		# Move entities to end of tree
		for child in root.get_children():
			if child.name in ["Player", "Dummy", "Zombie", "VisionLight"]:
				root.move_child(child, -1)
				
		var save_err = PackedScene.new()
		save_err.pack(root)
		ResourceSaver.save(save_err, cave_path)
		print("Saved CaveLevel.tscn")
	
	quit()
