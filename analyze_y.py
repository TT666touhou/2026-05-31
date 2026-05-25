import numpy as np
import matplotlib.pyplot as plt

def analyze_y_movement(data_file):
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

    J_HIPS = 0; J_HEAD = 2
    head_y = np.array([f['coords'][J_HEAD][1] - f['coords'][J_HIPS][1] for f in frames])
    
    print("--- 頭部 Y 軸 (上下) 運動分析 ---")
    print(f"Head Y Variance: {np.var(head_y):.4f}")
    print(f"Head Y StdDev: {np.std(head_y):.4f}")
    
    print("\n[逐幀 Y 座標 (Sample)]")
    for i in range(40, min(70, len(head_y))):
        val = head_y[i]
        print(f"Frame {i:03d}: {val:6.2f}")
        
    if np.std(head_y) < 1.0:
        print("\n>> 結論 (CONCLUSION):")
        print("使用者說得完全正確！頭部的上下運動幾乎是死的！")
        print("因為 Hips, Spine, 和 Head 的垂直彈簧 (2000, 1500, 1000) 太過強大，導致整個上半身像是在軌道上滑行，完全沒有物理遊戲該有的上下顛簸 (Bobbing) 與隨機彈跳。")

if __name__ == "__main__":
    analyze_y_movement("capture_data_physics.txt")
