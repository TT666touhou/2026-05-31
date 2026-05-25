import os
import cv2
import numpy as np

def analyze_walk_cycle(frames_dir):
    if not os.path.exists(frames_dir):
        print(f"Directory {frames_dir} not found.")
        return

    frames = sorted([f for f in os.listdir(frames_dir) if f.endswith('.png')])
    if not frames:
        print("No frames found.")
        return
        
    print(f"Found {len(frames)} frames. Assuming 15 fps (since we skipped every other frame of a 30fps video, or depending on youtube_extractor logic).")
    
    # We will output instructions for the agent to look at the differences between frames
    # Or calculate the horizontal movement of a specific colored blob (e.g., red head of the gladiator)
    
    # To find the gladiator's red head (or any character), let's look for red pixels
    # Stick ranger gladiator has a distinct red color for the head/helmet.
    # We will track the X coordinate of the red blob across frames.
    
    positions = []
    
    for frame_name in frames:
        img_path = os.path.join(frames_dir, frame_name)
        img = cv2.imread(img_path)
        
        # Convert to HSV to find red
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        
        # Red has two ranges in HSV
        lower_red1 = np.array([0, 100, 100])
        upper_red1 = np.array([10, 255, 255])
        lower_red2 = np.array([160, 100, 100])
        upper_red2 = np.array([180, 255, 255])
        
        mask1 = cv2.inRange(hsv, lower_red1, upper_red1)
        mask2 = cv2.inRange(hsv, lower_red2, upper_red2)
        mask = mask1 + mask2
        
        # Find contours
        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        if contours:
            # Get the largest red blob
            c = max(contours, key=cv2.contourArea)
            M = cv2.moments(c)
            if M["m00"] > 0:
                cX = int(M["m10"] / M["m00"])
                cY = int(M["m01"] / M["m00"])
                positions.append((frame_name, cX, cY))
            else:
                positions.append((frame_name, None, None))
        else:
            positions.append((frame_name, None, None))
            
    # Analyze the positions to find the speed
    valid_positions = [p for p in positions if p[1] is not None]
    if len(valid_positions) >= 2:
        start = valid_positions[0]
        end = valid_positions[-1]
        dist_x = end[1] - start[1]
        frames_diff = frames.index(end[0]) - frames.index(start[0])
        print(f"Gladiator moved {dist_x} pixels over {frames_diff} frames.")
        print(f"Average speed: {dist_x / frames_diff:.2f} pixels per frame.")
    
    # We also need to analyze the stride length. A full walk cycle is when the feet return to the same relative position.
    # This is harder to do automatically without complex pose estimation, but we can look at the Y coordinate of the head to find the bobbing frequency!
    
    if valid_positions:
        y_coords = [p[2] for p in valid_positions]
        # Find local peaks (lowest Y value in image coordinates means highest point)
        peaks = []
        for i in range(1, len(y_coords)-1):
            if y_coords[i] < y_coords[i-1] and y_coords[i] < y_coords[i+1]:
                peaks.append(i)
                
        if len(peaks) >= 2:
            avg_peak_dist = sum(peaks[i] - peaks[i-1] for i in range(1, len(peaks))) / (len(peaks) - 1)
            print(f"Average frames between head bobs (half walk cycle): {avg_peak_dist:.2f} frames")
            
            # Full walk cycle is 2 bobs
            full_cycle_frames = avg_peak_dist * 2
            print(f"Full walk cycle duration: {full_cycle_frames:.2f} frames")
            
            # Stride length = speed * full_cycle_frames
            speed_per_frame = dist_x / frames_diff
            stride_length = speed_per_frame * full_cycle_frames
            print(f"Calculated Stride Length: {stride_length:.2f} pixels")

if __name__ == "__main__":
    analyze_walk_cycle("youtube_frames_1080p")
