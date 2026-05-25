extends SceneTree

func _init():
	var stride_length = 128.0
	var speed = 250.0
	var dt = 0.016667
	
	var global_pos_x = 0.0
	
	print("Testing walking right:")
	for i in range(30):
		global_pos_x += speed * dt
		
		var global_phase = fposmod(global_pos_x / stride_length, 1.0)
		var phase = global_phase # Left foot phase
		
		# _get_foot_offset logic
		var offset_x = 0.0
		if phase < 0.5:
			var t = phase * 2.0
			offset_x = lerp(stride_length / 4.0, -stride_length / 4.0, t)
		else:
			var t = (phase - 0.5) * 2.0
			offset_x = lerp(-stride_length / 4.0, stride_length / 4.0, t)
			
		var foot_global_x = global_pos_x + offset_x
		
		print("Body X: %5.1f | Phase: %4.2f | Foot Local X: %5.1f | Foot Global X: %5.1f" % [global_pos_x, phase, offset_x, foot_global_x])
		
	quit()
