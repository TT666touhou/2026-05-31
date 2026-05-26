import sys
import math

def analyze():
    print("--- 逐幀傾斜分析 (Frame-by-Frame Tilt Analysis) ---")
    tilt_detected = False
    
    with open("capture_slime_physics.txt", "r", encoding="utf-16") as f:
        for line in f:
            if line.startswith("SLIME_DATA:"):
                parts = line.strip().split(",")
                frame = int(parts[0].split(":")[1])
                # Format: frame, tl.x, tl.y, tr.x, tr.y, bl.x, bl.y, br.x, br.y
                tl_x, tl_y = float(parts[1]), float(parts[2])
                tr_x, tr_y = float(parts[3]), float(parts[4])
                bl_x, bl_y = float(parts[5]), float(parts[6])
                br_x, br_y = float(parts[7]), float(parts[8])
                
                # 計算中軸線 (從底部中心到頂部中心)
                top_center_x = (tl_x + tr_x) / 2
                top_center_y = (tl_y + tr_y) / 2
                bot_center_x = (bl_x + br_x) / 2
                bot_center_y = (bl_y + br_y) / 2
                
                dx = top_center_x - bot_center_x
                dy = bot_center_y - top_center_y # invert Y so up is positive
                
                if dy == 0: dy = 0.001
                angle_deg = math.degrees(math.atan(dx / dy))
                
                if abs(angle_deg) > 1.5:
                    print(f"Frame {frame:03d}: 傾斜角 (Tilt Angle) = {angle_deg:.2f} 度 (dx={dx:.2f})")
                    tilt_detected = True
                    
    if tilt_detected:
        print("-> 結論: 分析證實，史萊姆在運動過程中發生了異常的傾斜。")
    else:
        print("-> 結論: 未檢測到傾斜。")

if __name__ == "__main__":
    analyze()
