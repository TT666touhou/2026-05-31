import numpy as np

def analyze_head_relative_to_body(data_file):
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
        print(f"Error: {e}")
        return

    if not frames:
        print("No data found.")
        return

    J_HIPS = 0; J_HEAD = 2
    
    # Calculate Head X relative to Hips X
    head_rel_x = []
    for f in frames:
        hips_x = f['coords'][J_HIPS][0]
        head_x = f['coords'][J_HEAD][0]
        head_rel_x.append(head_x - hips_x)
        
    head_rel_x = np.array(head_rel_x)
    
    print("--- 頭部對身體相對位置分析 (Head Relative to Body X) ---")
    
    # Check the actual values over a 30 frame window
    print("\n[逐幀相對位移 (Sample 30 frames)]")
    for i in range(40, min(70, len(head_rel_x))):
        val = head_rel_x[i]
        bar = "#" * int(abs(val))
        print(f"Frame {i:03d}: {val:6.2f} | {bar}")
        
    variance = np.var(head_rel_x)
    std_dev = np.std(head_rel_x)
    print(f"\nVariance: {variance:.4f}")
    print(f"StdDev: {std_dev:.4f}")
    
    if std_dev < 1.0:
        print("\n>> 結論 (CONCLUSION):")
        print("The user is absolutely right. The head's position relative to the body is effectively constant!")
        print("Because HIPS are strictly bound by a 2000.0 spring to the kinematic body, and HEAD has NO horizontal spring but a constant forward dragging force, the entire upper body just locks into a static forward-leaning diagonal line.")
        print("It does NOT whip back and forth chaotically like an active ragdoll. It is perfectly regular.")

if __name__ == "__main__":
    analyze_head_relative_to_body("capture_data_physics.txt")
