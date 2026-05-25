import cv2
import numpy as np
import os

def analyze_youtube_video(frames_dir):
    print(f"--- Analyzing Original Video Motion in {frames_dir} ---")
    if not os.path.exists(frames_dir):
        print("Frames directory not found.")
        return

    frames = sorted([f for f in os.listdir(frames_dir) if f.endswith(".png")])
    if not frames:
        print("No frames found.")
        return
        
    print(f"Total frames available: {len(frames)}")
    
    # We will try to track the player's head (the colored box) and maybe the feet.
    head_y_history = []
    
    for fname in frames:
        img_path = os.path.join(frames_dir, fname)
        img = cv2.imread(img_path)
        if img is None: continue
        
        # In Stick Ranger, players often have distinctive colored heads (e.g., Red for Gladiator, Blue for Sniper).
        # Let's find bright colored bounding boxes.
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        mask = cv2.inRange(hsv, (0, 100, 100), (180, 255, 255))
        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        heads = []
        for c in contours:
            x, y, w, h = cv2.boundingRect(c)
            # Filter for small squares (player/enemy heads)
            if 4 <= w <= 20 and 4 <= h <= 20 and 0.8 <= w/h <= 1.2:
                heads.append((x, y, w, h))
                
        if heads:
            # Assume the leftmost or rightmost one is our player (depends on context, usually left to right)
            heads.sort(key=lambda item: item[0])
            player_head = heads[0] # taking the leftmost colored head
            head_y_history.append(player_head[1])
        else:
            head_y_history.append(None)
            
    # Analyze head bobbing frequency
    valid_ys = [y for y in head_y_history if y is not None]
    if len(valid_ys) > 10:
        std_y = np.std(valid_ys)
        print(f"Head Y Standard Deviation: {std_y:.2f}")
        # Find peaks to count steps
        peaks = []
        for i in range(1, len(valid_ys)-1):
            if valid_ys[i] < valid_ys[i-1] and valid_ys[i] < valid_ys[i+1]:
                peaks.append(i)
        
        intervals = np.diff(peaks)
        if len(intervals) > 0:
            print(f"Step Intervals (frames between bobs): {intervals}")
            print(f"Average Interval: {np.mean(intervals):.2f}, StdDev: {np.std(intervals):.2f}")
            if np.std(intervals) > 2.0:
                print(">> CONCLUSION: The step interval varies significantly. The movement is IRREGULAR.")
            else:
                print(">> CONCLUSION: The step interval is CONSTANT. The movement is REGULAR (driven by sine/motor).")
                
        print("\nNote: Stick Ranger's engine uses 'springs' and 'particles'. Often, walking is simulated by continually rotating the hip joints using a motor, or altering rest lengths. Because it's an unconstrained physics system, overlapping feet or dragging causes chaotic stuttering on top of a regular mathematical cycle.")
    else:
        print("Not enough tracking data.")

if __name__ == "__main__":
    analyze_youtube_video("youtube_frames_1080p")
