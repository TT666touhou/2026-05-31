extends SceneTree
func _initialize():
    print("=== START TERRAIN COLLISION TEST ===")
    
    var c_scene = load("res://src/world/cave_01/CaveLevel.tscn")
    var lvl = c_scene.instantiate()
    root.add_child(lvl)
    
    await process_frame
    
    var lvl_p = lvl.get_node("Player")
    var drawer = lvl_p.get_node("ProceduralDrawer")
    
    # Force the player near the wall
    # Looking at tests/build_cave.gd, there is a wall at x=420 (width 40).
    # So its left edge is around x=400.
    # Let's move the player to x=390, y=0
    lvl_p.global_position = Vector2(390, 0)
    await process_frame
    
    var r_hand_idx = drawer.J.R_HAND
    
    # Apply a massive force to the right hand to push it through the wall
    drawer.verlet.points[r_hand_idx].pos += Vector2(100, 0)
    
    # Simulate a frame
    for i in range(5):
        await process_frame
    
    var final_pos = drawer.verlet.points[r_hand_idx].pos
    print("Hand final pos: ", final_pos)
    
    # If collision works, hand should be clamped to the wall surface (< 410)
    if final_pos.x < 410:
        print("=== TEST PASS ===")
    else:
        print("=== TEST FAIL: Clipped through wall! ===")
    quit()
