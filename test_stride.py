import math

stride_length = 128.0
speed = 250.0
dt = 0.016667
global_pos_x = 0.0

print("Testing walking right:")
for i in range(25):
    global_pos_x += speed * dt
    
    global_phase = (global_pos_x / stride_length) % 1.0
    phase = global_phase
    
    if phase < 0.5:
        t = phase * 2.0
        # Lerp logic
        offset_x = (stride_length / 4.0) * (1 - t) + (-stride_length / 4.0) * t
    else:
        t = (phase - 0.5) * 2.0
        offset_x = (-stride_length / 4.0) * (1 - t) + (stride_length / 4.0) * t
        
    foot_global_x = global_pos_x + offset_x
    print(f"Body X: {global_pos_x:5.1f} | Phase: {phase:4.2f} | Foot Local X: {offset_x:5.1f} | Foot Global X: {foot_global_x:5.1f}")
