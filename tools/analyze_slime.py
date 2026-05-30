import sys
import numpy as np

def analyze():
    top_y = []
    widths = []
    
    with open("capture_slime_physics.txt", "r", encoding="utf-16") as f:
        for line in f:
            if line.startswith("SLIME_DATA:"):
                parts = line.strip().split(",")
                frame = int(parts[0].split(":")[1])
                ty = float(parts[1])
                w = float(parts[2])
                top_y.append(ty)
                widths.append(w)

    if not top_y:
        print("No slime data found!")
        return

    top_y = np.array(top_y)
    widths = np.array(widths)

    print("--- 史萊姆物理分析 (Slime Physics Analysis) ---")
    print(f"Top Y Variance: {np.var(top_y):.4f}")
    print(f"Top Y StdDev: {np.std(top_y):.4f}")
    print(f"Width Variance: {np.var(widths):.4f}")
    print(f"Width StdDev: {np.std(widths):.4f}")
    
    if np.var(top_y) > 0.5 and np.var(widths) > 0.1:
        print("-> 成功: 史萊姆具備顯著的垂直形變與水平擠壓 (Q彈果凍效應)！")
    else:
        print("-> 失敗: 史萊姆太過僵硬，幾乎沒有形變。")

if __name__ == "__main__":
    analyze()
