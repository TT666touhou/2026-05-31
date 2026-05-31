extends SceneTree

func _init():
	print("Loading TileSet...")
	var tileset = load("res://src/world/terrain_kit/DarkwoodTileSet.tres")
	if not tileset:
		printerr("Failed to load DarkwoodTileSet.tres!")
		quit()
		return
	
	print("Rebuilding CaveLevel.tscn from scratch...")
	var cave_path = "res://src/world/cave_01/CaveLevel.tscn"
	
	var scene_root = NavigationRegion2D.new()
	scene_root.name = "CaveLevel"
	
	var script = load("res://src/world/cave_01/cave_level.gd")
	if script:
		scene_root.set_script(script)
		
	# Add new TileMapLayers
	var floor_layer = TileMapLayer.new()
	floor_layer.name = "FloorLayer"
	floor_layer.tile_set = tileset
	floor_layer.z_index = -10
	scene_root.add_child(floor_layer)
	floor_layer.owner = scene_root
				
	var wall_layer = TileMapLayer.new()
	wall_layer.name = "WallLayer"
	wall_layer.tile_set = tileset
	scene_root.add_child(wall_layer)
	wall_layer.owner = scene_root
	
	# -------- NEW LAYOUT LOGIC --------
	var floor_cells = {}
	
	# West Room: X: -25..25, Y: -18..18
	for x in range(-25, 26):
		for y in range(-18, 19):
			floor_cells[Vector2i(x, y)] = true
			
	# East Room: X: 26..62, Y: -12..12
	for x in range(26, 63):
		for y in range(-12, 13):
			floor_cells[Vector2i(x, y)] = true
			
	# Door/Corridor: X: 25..26, Y: -1..1
	for x in range(25, 27):
		for y in range(-1, 2):
			floor_cells[Vector2i(x, y)] = true
			
	var wall_cells = {}
	for cell in floor_cells.keys():
		# Add floor tile (random 0-15, 0-15)
		floor_layer.set_cell(cell, 1, Vector2i(randi() % 16, randi() % 16))
		
		# Check neighbors
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var n = cell + Vector2i(dx, dy)
				if not floor_cells.has(n):
					wall_cells[n] = true
					
	for cell in wall_cells.keys():
		# Add wall tile (random 0-15, 0-3)
		wall_layer.set_cell(cell, 2, Vector2i(randi() % 16, randi() % 4))
	# -----------------------------------
		
	var props_layer = Node2D.new()
	props_layer.name = "PropsLayer"
	props_layer.y_sort_enabled = true
	scene_root.add_child(props_layer)
	props_layer.owner = scene_root
	
	var barrel_pack = load("res://src/world/props/PropBarrel.tscn")
	if barrel_pack:
		var b1 = barrel_pack.instantiate()
		b1.position = Vector2(100, -50)
		props_layer.add_child(b1)
		b1.owner = scene_root
		var b2 = barrel_pack.instantiate()
		b2.position = Vector2(150, -40)
		props_layer.add_child(b2)
		b2.owner = scene_root
		
	var shelf_pack = load("res://src/world/props/PropBookshelf.tscn")
	if shelf_pack:
		var shelf = shelf_pack.instantiate()
		shelf.position = Vector2(-120, -80)
		props_layer.add_child(shelf)
		shelf.owner = scene_root
		
	var atmo_layer = CanvasLayer.new()
	atmo_layer.name = "AtmosphereLayer"
	scene_root.add_child(atmo_layer)
	atmo_layer.owner = scene_root
	
	var modulate = CanvasModulate.new()
	modulate.name = "CanvasModulate"
	modulate.color = Color(0, 0, 0, 1)
	scene_root.add_child(modulate)
	modulate.owner = scene_root
	
	var player_pack = load("res://src/entities/player/Player.tscn")
	if player_pack:
		var player = player_pack.instantiate()
		player.name = "Player"
		scene_root.add_child(player)
		player.owner = scene_root
		
	var dummy_pack = load("res://src/entities/dummy/Dummy.tscn")
	if dummy_pack:
		var dummy = dummy_pack.instantiate()
		dummy.name = "Dummy"
		dummy.position = Vector2(80, 0)
		scene_root.add_child(dummy)
		dummy.owner = scene_root
		
	var zombie_pack = load("res://src/entities/zombie/Zombie.tscn")
	if zombie_pack:
		var zombie = zombie_pack.instantiate()
		zombie.name = "Zombie"
		zombie.position = Vector2(600, 0)
		scene_root.add_child(zombie)
		zombie.owner = scene_root
		
	var save_err = PackedScene.new()
	save_err.pack(scene_root)
	ResourceSaver.save(save_err, cave_path)
	print("Saved CaveLevel.tscn")
	
	quit()
