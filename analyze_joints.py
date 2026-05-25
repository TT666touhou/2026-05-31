import numpy as np
import matplotlib.pyplot as plt

def analyze_joints(data_file):
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

    # Joint Index Constants
    J_HIPS = 0; J_SPINE = 1; J_HEAD = 2
    J_L_ELBOW = 3; J_L_HAND = 4
    J_R_ELBOW = 5; J_R_HAND = 6
    J_L_KNEE = 7; J_L_FOOT = 8
    J_R_KNEE = 9; J_R_FOOT = 10
    
    # Extract data
    extract = lambda j_idx, axis: np.array([f['coords'][j_idx][axis] for f in frames])
    
    hips_x = extract(J_HIPS, 0)
    
    head_rel_x = extract(J_HEAD, 0) - hips_x
    head_rel_y = extract(J_HEAD, 1) - extract(J_HIPS, 1)
    
    l_knee_rel_x = extract(J_L_KNEE, 0) - hips_x
    r_knee_rel_x = extract(J_R_KNEE, 0) - hips_x
    
    l_foot_rel_x = extract(J_L_FOOT, 0) - hips_x
    
    l_hand_rel_y = extract(J_L_HAND, 1) - hips_x
    
    print(f"--- 10-Second Physics Analysis Report (Frames: {len(frames)}) ---")
    
    print("\n[1] 頭部震盪 (Head Whiplash)")
    print(f"Head Rel X StdDev: {np.std(head_rel_x):.4f} (Previous was ~2.16)")
    head_peaks = np.sum(np.diff(np.sign(np.diff(head_rel_x))) != 0)
    print(f"Head X Direction Changes: {head_peaks} (High number indicates violent whiplash instead of smooth swaying)")
    
    print("\n[2] 腳底拖行與彈射 (Foot Sticking & Snapping)")
    foot_y = extract(J_L_FOOT, 1)
    ground_y = np.max(foot_y)
    step_lengths = []
    last_foot_down_x = 0
    foot_was_down = False
    
    for i in range(len(frames)):
        is_down = foot_y[i] >= ground_y - 1.0
        if is_down and not foot_was_down:
            if last_foot_down_x != 0:
                step_lengths.append(abs(extract(J_L_FOOT, 0)[i] - last_foot_down_x))
            last_foot_down_x = extract(J_L_FOOT, 0)[i]
        foot_was_down = is_down
        
    print(f"Avg Step Length: {np.mean(step_lengths):.2f}")
    print(f"Step Length StdDev: {np.std(step_lengths):.4f} (Previous was ~1.01)")
    if np.std(step_lengths) > 2.0:
        print("-> 成功: 步伐具有顯著的不對稱性，摩擦力成功導致了拖行與突進！")
        
    print("\n[3] 膝蓋反折與抽搐 (Knee Bending Chaos)")
    # When foot is stuck but body moves forward, knee relative X will be dragged backwards until snap
    knee_variance = np.var(l_knee_rel_x)
    print(f"L Knee Relative X Variance: {knee_variance:.2f}")
    
    print("\n[4] 手部/手肘無重力擺盪 (Hands/Elbows)")
    print(f"L Hand Relative Y StdDev: {np.std(l_hand_rel_y):.4f}")
    
    print("\n結論: 如果 Step StdDev 和 Head Direction Changes 大幅增加，代表 Motor IK 成功將時間函數轉換成了物理系統的湧現混沌。")

if __name__ == "__main__":
    analyze_joints("capture_data_physics.txt")
