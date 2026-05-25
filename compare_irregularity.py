import numpy as np

def analyze_irregularity(data_file):
    frames = []
    try:
        with open(data_file, 'r', encoding='utf-16') as f:
            for line in f:
                if line.startswith("DATA:"):
                    parts = line.strip().split(',')
                    frame_idx = int(parts[0].split(':')[1])
                    coords = []
                    for i in range(1, len(parts), 2):
                        coords.append((float(parts[i]), float(parts[i+1])))
                    frames.append({'frame': frame_idx, 'coords': coords})
    except Exception as e:
        print(f"Error reading file: {e}")
        return

    if not frames:
        print("No data found.")
        return

    head_x = np.array([f['coords'][2][0] for f in frames])
    hips_x = np.array([f['coords'][0][0] for f in frames])
    l_foot_x = np.array([f['coords'][8][0] for f in frames])
    
    # Analyze Head Relative Movement Variance
    head_relative_x = head_x - hips_x
    head_fft = np.fft.fft(head_relative_x - np.mean(head_relative_x))
    power_spectrum = np.abs(head_fft)**2
    
    # If the movement is perfectly regular, power_spectrum will have 1 or 2 massive spikes and near-zero elsewhere.
    # We can measure "chaos" by looking at how spread out the frequencies are.
    
    # Calculate step distances (difference between consecutive foot placements when foot is on ground)
    # Foot is considered on ground when its Y velocity is near 0 or Y is max
    foot_y = np.array([f['coords'][8][1] for f in frames])
    ground_y = np.max(foot_y)
    
    step_lengths = []
    foot_was_down = False
    last_foot_down_x = 0
    
    for i in range(len(frames)):
        is_down = foot_y[i] > ground_y - 1.0
        if is_down and not foot_was_down:
            if last_foot_down_x != 0:
                step_lengths.append(abs(l_foot_x[i] - last_foot_down_x))
            last_foot_down_x = l_foot_x[i]
        foot_was_down = is_down
        
    print(f"Total Frames Analyzed: {len(frames)} (approx {len(frames)/60:.1f} seconds)")
    
    if step_lengths:
        print(f"Average Step Length: {np.mean(step_lengths):.2f}")
        print(f"Step Length Standard Deviation: {np.std(step_lengths):.4f}")
        if np.std(step_lengths) < 1.0:
            print(">> CRITICAL ANALYSIS: Step length has virtually ZERO variance. Movement is perfectly regular (robotic).")
    else:
        print("Not enough step data.")
        
    # Check head bobbing regularity
    head_bob_std = np.std(head_relative_x)
    print(f"Head Relative X StdDev: {head_bob_std:.4f}")
    
    print("\n--- DIAGNOSIS ---")
    print("The current Godot implementation relies on 'fposmod(global_x / STRIDE)' which creates a 100% deterministic, perfect sine-wave step cycle.")
    print("In the original Youtube video, Stick Ranger uses physics-driven, chaotic step triggers where limbs snap irregularly based on collisions, friction, and tension.")

if __name__ == "__main__":
    analyze_irregularity("capture_data_10s.txt")
