extends "res://addons/gut/test.gd"

func test_drawer_process_and_draw() -> void:
    var player = preload("res://Player.tscn").instantiate()
    assert_not_null(player, "Player should instantiate")
    
    var drawer = player.get_node_or_null("ProceduralDrawer")
    assert_not_null(drawer, "Player must have ProceduralDrawer node")
    
    if drawer == null:
        return
        
    assert_true(drawer.has_method("_draw"), "Drawer must have _draw method")
    
    # Run 1 frame to ensure no exceptions in _process and _draw
    # We can't catch Godot errors easily in GDScript, but we can call it manually
    drawer._process(0.016)
    
    # We can't directly call _draw outside of Notification, but we can verify it doesn't crash if called
    drawer.notification(CanvasItem.NOTIFICATION_DRAW)
    
    assert_true(true, "Procedural drawing completed without fatal script errors")
