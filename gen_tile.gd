extends SceneTree
func _init():
	var root = Node2D.new()
	root.name = "Root"
	var l = TileMapLayer.new()
	l.name = "Layer"
	root.add_child(l)
	l.owner = root
	l.set_cell(Vector2i(0,0), 1, Vector2i(0,0))
	
	var p = PackedScene.new()
	p.pack(root)
	ResourceSaver.save(p, "res://TestScene.tscn")
	print("Saved TestScene.tscn")
	quit()
