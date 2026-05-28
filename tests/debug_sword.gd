extends SceneTree

func _init():
    var packed = load('res://src/items/weapons/sword.tscn')
    var inst = packed.instantiate()
    print('Hitbox script: ', inst.get_node('Hitbox').get_script())
    print('Hitbox shape: ', inst.get_node('Hitbox/CollisionShape2D').shape)
    print('Hitbox mask: ', inst.get_node('Hitbox').collision_mask)
    quit()
