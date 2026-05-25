extends SceneTree

var frames = 0
var main_scene

func _init():
	main_scene = load("res://Main.tscn").instantiate()
	root.add_child(main_scene)
	print("Started capturing test...")

func _process(delta):
	frames += 1
	
	if frames == 5:
		var ev = InputEventAction.new()
		ev.action = "ui_right"
		ev.pressed = true
		Input.parse_input_event(ev)
		print("Pressed right arrow...")
		
	if frames > 5 and frames % 4 == 0:
		var img = root.get_viewport().get_texture().get_image()
		var frame_num = (frames - 5) / 4
		if frame_num <= 600:
			var filename = "debug_frames/godot/frame_%04d.png" % frame_num
			img.save_png(filename)
			print("Captured frame: ", filename)
		
	if frames == 600: # Run for 10 seconds at 60fps
		var ev = InputEventAction.new()
		ev.action = "ui_right"
		ev.pressed = false
		Input.parse_input_event(ev)
		print("Released right arrow...")
		
	if frames >= 260:
		print("Finished capturing Godot frames! Quitting...")
		quit()
