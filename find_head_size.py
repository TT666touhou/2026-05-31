import cv2
import numpy as np

def find_player_heads(image_path):
    print(f"--- Analyzing Heads in {image_path} ---")
    img = cv2.imread(image_path)
    if img is None:
        return
        
    # Convert to HSV to find colorful regions
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    
    # Player heads are usually highly saturated and bright
    # Saturation > 100, Value > 100
    mask = cv2.inRange(hsv, (0, 100, 100), (180, 255, 255))
    
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    head_sizes = []
    for c in contours:
        x, y, w, h = cv2.boundingRect(c)
        # Heads are roughly square and relatively small (not health bars)
        if 4 <= w <= 20 and 4 <= h <= 20 and 0.8 <= w/h <= 1.2:
            head_sizes.append((w, h))
            
    if head_sizes:
        print(f"Found potential heads with sizes: {head_sizes}")
        avg_w = sum(s[0] for s in head_sizes) / len(head_sizes)
        avg_h = sum(s[1] for s in head_sizes) / len(head_sizes)
        print(f"Average Head Size: {avg_w:.1f} x {avg_h:.1f}")
    else:
        print("No heads found.")

if __name__ == "__main__":
    import os
    frames_dir = "youtube_frames_1080p"
    if os.path.exists(frames_dir):
        frames = sorted([f for f in os.listdir(frames_dir) if f.endswith(".png")])
        for f in frames[:3]:
            find_player_heads(os.path.join(frames_dir, f))
