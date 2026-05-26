extends SceneTree

var slime_scene = preload("res://entities/slime/slime.tscn")
var slime: CharacterBody2D
var capture_timer: int = 0
var frame_count: int = 0

func _init() -> void:
	print("Starting slime test capture...")
	var test_root = Node2D.new()
	root.add_child(test_root)
	
	# Add a static floor so it can bounce
	var static_body = StaticBody2D.new()
	static_body.collision_layer = 1
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(1000, 20)
	col.shape = rect
	col.position = Vector2(0, 10)
	static_body.add_child(col)
	test_root.add_child(static_body)
	
	slime = slime_scene.instantiate()
	slime.position = Vector2(0, -50)
	test_root.add_child(slime)
	
	var cam = Camera2D.new()
	cam.position = Vector2(0, -20)
	cam.zoom = Vector2(4, 4)
	test_root.add_child(cam)
	
	DirAccess.make_dir_recursive_absolute("res://slime_frames")

func _process(delta: float) -> bool:
	if frame_count > 150:
		return true
		
	var drawer = slime.get_node("SlimeDrawer")
	if drawer and drawer.verlet and drawer.verlet.points.size() > 0:
		var top_left = drawer.verlet.points[drawer.S.TOP_LEFT].pos
		var top_right = drawer.verlet.points[drawer.S.TOP_RIGHT].pos
		var bot_left = drawer.verlet.points[drawer.S.BOTTOM_LEFT].pos
		var bot_right = drawer.verlet.points[drawer.S.BOTTOM_RIGHT].pos
		
		print("SLIME_DATA:%d,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f" % [
			frame_count, 
			top_left.x, top_left.y, 
			top_right.x, top_right.y,
			bot_left.x, bot_left.y,
			bot_right.x, bot_right.y
		])
		
	capture_timer += 1
	if capture_timer >= 2:
		capture_timer = 0
		var image = root.get_viewport().get_texture().get_image()
		if image:
			image.save_png("res://slime_frames/frame_%04d.png" % frame_count)
	
	frame_count += 1
	return false
