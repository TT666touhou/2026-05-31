extends "res://addons/gut/test.gd"

func test_main_scene_structure() -> void:
    var main = preload("res://Main.tscn").instantiate()
    assert_not_null(main, "Main.tscn should instantiate successfully")
    
    assert_true(main.has_node("Terrain"), "Main must have a 'Terrain' node")
    assert_true(main.has_node("GroundBody/CollisionShape2D"), "Main must have 'GroundBody/CollisionShape2D'")
    
    var collision_shape = main.get_node("GroundBody/CollisionShape2D")
    var shape = collision_shape.shape
    assert_not_null(shape, "CollisionShape2D must have a valid shape assigned")
    
    if shape != null:
        assert_eq(shape.size, Vector2(640, 64), "Terrain collision shape size must be Vector2(640, 64)")

# EOF
