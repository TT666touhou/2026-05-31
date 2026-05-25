import numpy as np
import matplotlib.pyplot as plt

def analyze_motion(data_file):
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
                
    head_x = np.array([f['coords'][2][0] for f in frames])
    hips_x = np.array([f['coords'][0][0] for f in frames])
    head_relative_x = head_x - hips_x
    
    plt.figure(figsize=(10, 4))
    plt.plot([f['frame'] for f in frames], head_relative_x, label="Head Relative X")
    plt.title("Head Relative X Oscillation")
    plt.xlabel("Frame")
    plt.ylabel("Relative X Position")
    plt.grid(True)
    plt.savefig("head_oscillation.png")
    print("Saved plot to head_oscillation.png")

if __name__ == "__main__":
    analyze_motion("capture_data.txt")
