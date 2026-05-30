extends SceneTree

func _init():
    var light = PointLight2D.new()
    light.range_item_cull_mask = 3
    light.shadow_item_cull_mask = 3
    var packed = PackedScene.new()
    packed.pack(light)
    ResourceSaver.save(packed, "res://generated_light.tscn")
    quit()
