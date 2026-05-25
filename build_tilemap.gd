extends SceneTree

func _init():
	print("Starting TileMap physics generation (Fix)...")
	var packed = load("res://Main.tscn")
	var scene = packed.instantiate()
	
	var terrain = scene.get_node("Terrain")
	if terrain and terrain is TileMapLayer:
		var tileset = TileSet.new()
		tileset.tile_size = Vector2i(16, 16)
		
		# Add physics layer FIRST
		tileset.add_physics_layer(0)
		
		var source = TileSetAtlasSource.new()
		source.texture = load("res://assets/kenney_1-bit-pack/Tilemap/tileset_legacy.png")
		source.texture_region_size = Vector2i(16, 16)
		source.create_tile(Vector2i(2, 8))
		
		# Add source to tileset SO IT KNOWS ABOUT PHYSICS LAYERS
		tileset.add_source(source, 0)
		
		# NOW get tile data and add collision
		var tile_data = source.get_tile_data(Vector2i(2, 8), 0)
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
			Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
		]))
		
		terrain.tile_set = tileset
		
		for r in range(18, 22):
			for c in range(40):
				terrain.set_cell(Vector2i(c, r), 0, Vector2i(2, 8))
				
		terrain.position.y = 8.0
		
	var ground = scene.get_node_or_null("GroundBody")
	if ground:
		scene.remove_child(ground)
		ground.free()
		
	scene.set_script(null)
	
	var new_packed = PackedScene.new()
	new_packed.pack(scene)
	ResourceSaver.save(new_packed, "res://Main.tscn")
	
	print("TileMap successfully embedded with physics into Main.tscn")
	quit()
