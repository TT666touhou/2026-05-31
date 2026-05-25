import numpy as np
import matplotlib.pyplot as plt

def analyze_motion(data_file):
    joints = ["HIPS", "SPINE_TOP", "HEAD_CENTER", "L_ELBOW", "L_HAND", "R_ELBOW", "R_HAND", "L_KNEE", "L_FOOT", "R_KNEE", "R_FOOT"]
    
    # Read data
    frames = []
    with open(data_file, 'r', encoding='utf-16') as f:
        for line in f:
            if line.startswith("DATA:"):
                parts = line.strip().split(',')
                frame_idx = int(parts[0].split(':')[1])
                coords = []
                for i in range(1, len(parts), 2):
                    coords.append((float(parts[i]), float(parts[i+1])))
                frames.append({'frame': frame_idx, 'coords': coords})
                
    if not frames:
        print("No DATA found in", data_file)
        return
        
    print(f"Loaded {len(frames)} frames of data.")
    
    # 1. Check Hand Overlap
    l_hands = np.array([f['coords'][4] for f in frames])
    r_hands = np.array([f['coords'][6] for f in frames])
    
    hand_dist = np.linalg.norm(l_hands - r_hands, axis=1)
    print("\n--- Hand Overlap Analysis ---")
    print(f"Max distance between hands: {np.max(hand_dist):.2f} pixels")
    print(f"Average distance between hands: {np.mean(hand_dist):.2f} pixels")
    if np.max(hand_dist) < 1.0:
        print("CRITICAL ISSUE: Hands are perfectly overlapping (distance < 1 px).")
    
    # 2. Check Head Horizontal Spring Oscillation
    head_x = np.array([f['coords'][2][0] for f in frames])
    hips_x = np.array([f['coords'][0][0] for f in frames])
    
    # The head's offset relative to the hips
    head_relative_x = head_x - hips_x
    
    print("\n--- Head Oscillation Analysis ---")
    # A spring oscillation will have multiple zero-crossings or direction changes
    # Let's count the number of direction changes in relative velocity
    rel_vel = np.diff(head_relative_x)
    direction_changes = np.sum(np.diff(np.sign(rel_vel)) != 0)
    print(f"Head horizontal relative movement: min={np.min(head_relative_x):.2f}, max={np.max(head_relative_x):.2f}")
    print(f"Direction changes in head velocity (indicates oscillation/vibration): {direction_changes}")
    print("Head X Sample (Frames 40-60):")
    print(", ".join([f"{x:.2f}" for x in head_relative_x[40:61]]))
    if direction_changes > 10:
        print("CRITICAL ISSUE: Head is vibrating like an underdamped spring.")
        
    # 3. Check Foot "Goofiness" (Step frequency/pattern)
    l_feet_x = np.array([f['coords'][8][0] for f in frames])
    r_feet_x = np.array([f['coords'][10][0] for f in frames])
    
    # Are the feet moving properly out of phase?
    print("\n--- Feet Motion Analysis ---")
    l_foot_step_size = np.max(l_feet_x) - np.min(l_feet_x)
    print(f"Left Foot total travel: {l_foot_step_size:.2f} pixels")

if __name__ == "__main__":
    analyze_motion("capture_data.txt")
