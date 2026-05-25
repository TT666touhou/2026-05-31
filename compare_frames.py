import os
import cv2
import numpy as np

def analyze_posture(frame_path):
    if not os.path.exists(frame_path):
        print(f"Error: {frame_path} not found.")
        return
        
    print(f"--- Analyzing Posture for {os.path.basename(frame_path)} ---")
    img = cv2.imread(frame_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # In Godot frames, the stickman is drawn in pure white (255)
    _, mask = cv2.threshold(gray, 240, 255, cv2.THRESH_BINARY)
    
    # Find all white pixels
    y_coords, x_coords = np.where(mask == 255)
    
    if len(y_coords) == 0:
        print("No stickman found.")
        return
        
    # Highest Y is the lowest value (top of image) -> This is the HEAD
    # Lowest Y is the highest value (bottom) -> These are the FEET
    head_y = np.min(y_coords)
    feet_y = np.max(y_coords)
    
    # Let's find the head box specifically
    # The head is drawn as a 6x6 rect at the top
    # We can cluster the points
    head_pixels = y_coords < head_y + 8
    head_x_avg = np.mean(x_coords[head_pixels])
    head_y_avg = np.mean(y_coords[head_pixels])
    
    print(f"Head Position: ({head_x_avg:.1f}, {head_y_avg:.1f})")
    print(f"Feet Ground Y: {feet_y}")
    print(f"Total Character Height: {feet_y - head_y} pixels")
    
    # Calculate the horizontal balance (unbalance)
    # The feet are spread out on the ground. Let's find the center of the feet
    feet_pixels = y_coords > feet_y - 2
    if len(x_coords[feet_pixels]) > 0:
        feet_min_x = np.min(x_coords[feet_pixels])
        feet_max_x = np.max(x_coords[feet_pixels])
        feet_center_x = (feet_min_x + feet_max_x) / 2
        
        # Calculate lean (offset from feet center to head)
        lean_offset = head_x_avg - feet_center_x
        print(f"Feet Spread: {feet_min_x} to {feet_max_x} (Center: {feet_center_x:.1f})")
        print(f"Forward Lean (Unbalance): {lean_offset:.1f} pixels")
        
        if lean_offset > 0:
            print("Posture: Leaning Forward (Classic Stick Ranger dash pose!)")
        elif lean_offset < 0:
            print("Posture: Leaning Backward")
        else:
            print("Posture: Perfectly Straight (Too rigid)")
            
    # Check if hips are elevated
    if feet_y - head_y > 20:
        print("Verdict: The character is successfully STANDING UP! Buoyancy is working.")
    else:
        print("Verdict: The character is COLLAPSED (Height too small).")

if __name__ == "__main__":
    analyze_posture("debug_frames/godot/frame_0000.png")  # Idle/start
    print()
    analyze_posture("debug_frames/godot/frame_0003.png")  # Mid stride
