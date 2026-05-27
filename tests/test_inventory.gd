extends SceneTree
func _initialize():
    print("=== START INVENTORY TEST ===")
    var mgr = load("res://src/systems/inventory/InventoryManager.gd").new()
    mgr._ready()
    
    var ItemData = load("res://src/systems/inventory/ItemData.gd")
    var sword = ItemData.new("sword", "Sword", Vector2i(1, 3))
    var bow = ItemData.new("bow", "Bow", Vector2i(2, 3))
    
    var b1 = mgr.add_to_backpack(sword, Vector2i(0, 0))
    print("Add sword (1x3) at 0,0: ", b1)
    var b2 = mgr.add_to_backpack(bow, Vector2i(0, 0))
    print("Add bow (2x3) at 0,0 (overlap): ", b2)
    var b3 = mgr.add_to_backpack(bow, Vector2i(1, 0))
    print("Add bow (2x3) at 1,0: ", b3)
    var b4 = mgr.add_to_backpack(sword, Vector2i(0, 2))
    print("Add sword (1x3) at 0,2 (overlap bottom): ", b4)
    var b5 = mgr.add_to_backpack(sword, Vector2i(0, 3))
    print("Add sword (1x3) at 0,3 (out of bounds): ", b5)
    
    var b6 = mgr.auto_add_to_backpack(sword)
    print("Auto add sword: ", b6)
    
    mgr.set_hotbar_item(0, bow)
    print("Set hotbar 0 to bow, slot 0 is null? ", mgr.hotbar_items[0] == null)
    
    if b1 and not b2 and b3 and not b4 and not b5 and b6:
        print("=== TEST PASS ===")
    quit()
