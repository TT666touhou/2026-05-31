# validation.gd
# Automated headless validation script for checking implementation correctness.
extends SceneTree

func _init() -> void:
	print("--- STARTING HEADLESS VALIDATION RUN ---")
	call_deferred("_run_tests")

func _run_tests() -> void:
	var success = true
	
	# Test 1: Load and generate dungeon level, check synchronous navigation setup
	print("[TEST 1] Testing Synchronous Navigation Setup...")
	var dungeon_scene = load("res://src/world/dungeon/DungeonLevel.tscn")
	if not dungeon_scene:
		print("  FAIL: Cannot load DungeonLevel.tscn")
		quit(1)
		return
		
	var dungeon = dungeon_scene.instantiate()
	root.add_child(dungeon)
	
	# Generate map
	dungeon.generate_floor(12345) # Seed 12345
	
	# Check if NavigationRegion2D exists synchronously (must not be null or deferred after ready)
	var nav_region = dungeon.get_node_or_null("NavigationRegion2D")
	if not nav_region:
		print("  FAIL: NavigationRegion2D was not created synchronously!")
		success = false
	else:
		print("  PASS: NavigationRegion2D exists synchronously.")
		var nav_poly = nav_region.navigation_polygon
		if not nav_poly:
			print("  FAIL: NavigationPolygon is null!")
			success = false
		else:
			var outline_count = nav_poly.get_outline_count()
			print("  INFO: NavigationPolygon outline count is: ", outline_count)
			# An optimized polygon should have 1 map border outline + number of wall outline holes (e.g. < 500),
			# whereas unoptimized had 1500+ tile outlines.
			if outline_count > 1000:
				print("  FAIL: NavigationPolygon is not optimized! Outline count too high: ", outline_count)
				success = false
			else:
				print("  PASS: NavigationPolygon is optimized.")

	# Test 2: Check Wall Light Mask and Occluder Mask
	print("[TEST 2] Testing Wall Light Mask and Occluder Mask...")
	var dungeon_renderer = dungeon.get_node_or_null("DungeonRenderer")
	if not dungeon_renderer:
		print("  FAIL: DungeonRenderer not found!")
		success = false
	else:
		var wall_renderer = dungeon_renderer.get_node_or_null("WallRenderer")
		if not wall_renderer:
			print("  FAIL: WallRenderer child node not found in DungeonRenderer!")
			success = false
		else:
			if wall_renderer.light_mask != 8:
				print("  FAIL: WallRenderer light_mask is ", wall_renderer.light_mask, ", expected 8 (Layer 4)")
				success = false
			else:
				print("  PASS: WallRenderer light_mask is correct (8).")
				
		# Check occluders mask
		if dungeon_renderer.light_occluders.size() > 0:
			var first_occ = dungeon_renderer.light_occluders[0]
			if first_occ.occluder_light_mask != 7:
				print("  FAIL: LightOccluder2D occluder_light_mask is ", first_occ.occluder_light_mask, ", expected 7 (Layer 1+2+3)")
				success = false
			else:
				print("  PASS: LightOccluder2D occluder_light_mask is correct (7).")
		else:
			print("  WARNING: No occluders generated to test!")
			
		# Test 2.5: Check Darkwood LOS and Fog of War Shading Configuration
		print("[TEST 2.5] Testing Darkwood LOS and Fog of War Shading...")
		var canvas_mod = dungeon.get_node_or_null("CanvasModulate")
		if not canvas_mod:
			print("  FAIL: CanvasModulate not found!")
			success = false
		else:
			if canvas_mod.color != Color(0, 0, 0, 1):
				print("  FAIL: CanvasModulate color is ", canvas_mod.color, ", expected Color(0, 0, 0, 1) for total occlusion!")
				success = false
			else:
				print("  PASS: CanvasModulate color is correct (pure black).")
				
		var player_node = dungeon.player_instance
		if player_node:
			var fog_light = player_node.get_node_or_null("FogLight")
			if not fog_light:
				print("  FAIL: Player FogLight not found!")
				success = false
			else:
				if fog_light.range_item_cull_mask != 13:
					print("  FAIL: FogLight range_item_cull_mask is ", fog_light.range_item_cull_mask, ", expected 13 (excludes Layer 2/Enemies)!")
					success = false
				else:
					print("  PASS: FogLight range_item_cull_mask is correct (13).")
				if fog_light.energy < 0.3:
					print("  FAIL: FogLight energy is ", fog_light.energy, ", expected >= 0.3 for visible memory!")
					success = false
				else:
					print("  PASS: FogLight energy is correct.")
				if not fog_light.shadow_enabled:
					print("  FAIL: FogLight shadow_enabled is false, expected true!")
					success = false
				else:
					print("  PASS: FogLight shadow_enabled is correct.")
					
		# Check Zombie scene Drawer light mask
		var zombie_scene = load("res://src/entities/zombie/Zombie.tscn")
		if not zombie_scene:
			print("  FAIL: Cannot load Zombie.tscn!")
			success = false
		else:
			var zombie_instance = zombie_scene.instantiate()
			var z_drawer = zombie_instance.get_node_or_null("ProceduralDrawer")
			if not z_drawer:
				print("  FAIL: Zombie ProceduralDrawer not found!")
				success = false
			else:
				if z_drawer.light_mask != 2:
					print("  FAIL: Zombie drawer light_mask is ", z_drawer.light_mask, ", expected 2 (Layer 2)!")
					success = false
				else:
					print("  PASS: Zombie drawer light_mask is correct (2).")
			zombie_instance.queue_free()

	# Test 3: Check Player and Weapon scaling
	print("[TEST 3] Testing Player and Weapon Scaling...")
	var player = dungeon.player_instance
	if not player:
		print("  FAIL: Player instance not found!")
		success = false
	else:
		var drawer = player.get_node_or_null("ProceduralDrawer")
		if not drawer:
			print("  FAIL: Player ProceduralDrawer not found!")
			success = false
		else:
			# Verify player FOV Light Masks
			var player_fov = player.get_node_or_null("VisionLight")
			if not player_fov:
				print("  FAIL: Player VisionLight not found!")
				success = false
			else:
				if player_fov.range_item_cull_mask != 15:
					print("  FAIL: Player FOV range_item_cull_mask is ", player_fov.range_item_cull_mask, ", expected 15 (Layer 1+2+3+4)")
					success = false
				else:
					print("  PASS: Player FOV range_item_cull_mask is correct (15).")
			
			# Test dynamic scale factor updates
			print("  Setting player scale to 2.0...")
			player.scale = Vector2(2.0, 2.0)
			
			# Wait a few physics frames for drawer to process scale change
			await physics_frame
			await physics_frame
			await physics_frame
			
			if drawer.scale_factor != 2.0:
				print("  FAIL: ProceduralDrawer scale_factor did not update dynamically to 2.0! Current: ", drawer.scale_factor)
				success = false
			else:
				print("  PASS: ProceduralDrawer scale_factor updated dynamically to 2.0.")
				
				# Check if unarmed hitbox positions are correctly updated in global space
				var unarmed_scene = load("res://src/items/weapons/unarmed.tscn")
				if unarmed_scene:
					drawer.equip(unarmed_scene)
					await physics_frame
					var unarmed = drawer.get_node_or_null("Unarmed")
					if unarmed:
						var l_hitbox = unarmed.get_node("LeftHitbox")
						var r_hitbox = unarmed.get_node("RightHitbox")
						
						# Verify position is not double scaled.
						# global_position should exactly match the physical points pos.
						var physics = drawer.verlet
						var l_hand_pos = physics.points[drawer.J.L_HAND].pos
						var r_hand_pos = physics.points[drawer.J.R_HAND].pos
						
						if l_hitbox.global_position.distance_to(l_hand_pos) > 1.0 or r_hitbox.global_position.distance_to(r_hand_pos) > 1.0:
							print("  FAIL: Unarmed hitbox positions are offset! L_Hitbox: ", l_hitbox.global_position, " vs Hand: ", l_hand_pos)
							success = false
						else:
							print("  PASS: Unarmed hitbox positions match hands perfectly at scale 2.0.")
							
	# Test 4: Zombie movement and pathfinding check
	print("[TEST 4] Testing Zombie Pathfinding...")
	if dungeon.enemy_instances.size() > 0:
		var zombie = dungeon.enemy_instances[0]
		
		# Set zombie to chase state and wait for navigation map sync
		zombie.current_state = zombie.State.CHASE
		zombie.nav_agent.target_position = player.global_position
		
		# Wait for pathfinding update (requires 2 physics frames in Godot 4)
		await physics_frame
		await physics_frame
		
		var next_pos = zombie.nav_agent.get_next_path_position()
		var dist_to_next = zombie.global_position.distance_to(next_pos)
		print("  INFO: Zombie position: ", zombie.global_position)
		print("  INFO: Target (Player) position: ", player.global_position)
		print("  INFO: Next path position: ", next_pos)
		
		if zombie.nav_agent.is_navigation_finished():
			print("  FAIL: Navigation finished immediately or could not find a path!")
			success = false
		elif dist_to_next < 1.0:
			print("  FAIL: Zombie navigation path is stuck at current position (no path found)!")
			success = false
		else:
			print("  PASS: Zombie navigation is functional and pathing towards player.")
	else:
		print("  WARNING: No zombies spawned to test pathfinding!")
		
	# Clean up dungeon scene
	dungeon.queue_free()
	await process_frame
	
	if success:
		print("\n*** ALL TESTS PASSED SUCCESSFULLY! ***")
		quit(0)
	else:
		print("\n*** SOME TESTS FAILED! ***")
		quit(1)
