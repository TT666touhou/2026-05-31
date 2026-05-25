import cv2
import numpy as np
import math

def get_line_lengths(image_path):
    img = cv2.imread(image_path)
    if img is None:
        return
        
    print(f"--- Analyzing Proportions in {image_path} ---")
    
    # Convert to grayscale
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # In Stick Ranger, the body lines are very dark.
    # Background is usually white/gray.
    _, mask = cv2.threshold(gray, 50, 255, cv2.THRESH_BINARY_INV)
    
    # Use Hough Line Transform to find line segments
    # This is perfect for stick figures!
    lines = cv2.HoughLinesP(mask, 1, np.pi/180, threshold=15, minLineLength=5, maxLineGap=2)
    
    if lines is None:
        print("No lines found.")
        return
        
    vertical_lines = []
    diagonal_lines = []
    
    for line in lines:
        x1, y1, x2, y2 = line[0]
        length = math.sqrt((x2 - x1)**2 + (y2 - y1)**2)
        
        # Filter out background elements (UI, ground, etc.)
        if length > 20:
            continue
            
        angle = abs(math.atan2(y2 - y1, x2 - x1) * 180 / math.pi)
        
        # Normalize angle to 0-90
        if angle > 90:
            angle = 180 - angle
            
        if angle > 70:
            vertical_lines.append(length)
        elif 20 < angle < 70:
            diagonal_lines.append(length)
            
    if vertical_lines:
        spine_len = max(vertical_lines)
        print(f"Max Vertical Line Length (Likely Spine): {spine_len:.1f} pixels")
    else:
        spine_len = 0
        
    if diagonal_lines:
        # The legs and arms are diagonal
        diag_len = np.mean(sorted(diagonal_lines)[-4:]) if len(diagonal_lines) >= 4 else max(diagonal_lines)
        print(f"Average Longest Diagonal Lines (Likely Limbs): {diag_len:.1f} pixels")
    else:
        diag_len = 0
        
    if spine_len > 0 and diag_len > 0:
        print(f"Ratio Limbs / Spine = {diag_len / spine_len:.2f}")

if __name__ == "__main__":
    import os
    frames_dir = "youtube_frames_1080p"
    if os.path.exists(frames_dir):
        frames = sorted([f for f in os.listdir(frames_dir) if f.endswith(".png")])
        # Analyze a few frames
        for f in frames[:5]:
            get_line_lengths(os.path.join(frames_dir, f))
