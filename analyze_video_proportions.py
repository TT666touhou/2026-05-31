import cv2
import numpy as np
import os

def analyze_proportions(image_path):
    print(f"Analyzing {image_path}...")
    img = cv2.imread(image_path)
    if img is None:
        print("Could not read image.")
        return
        
    # The game background is usually white/gray. Stick lines are black/dark.
    # We look for a distinct colored head (e.g. Red for Gladiator or Green for Sniper)
    # Let's find bright red pixels (Gladiator head)
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    
    # Red has two ranges in HSV
    mask1 = cv2.inRange(hsv, (0, 150, 150), (10, 255, 255))
    mask2 = cv2.inRange(hsv, (170, 150, 150), (180, 255, 255))
    red_mask = mask1 | mask2
    
    contours, _ = cv2.findContours(red_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    head_c = None
    for c in sorted(contours, key=cv2.contourArea, reverse=True):
        x, y, w, h = cv2.boundingRect(c)
        if 0.5 < w/h < 2.0 and w > 4:
            head_c = c
            break
            
    if head_c is None:
        print("No red head found in this frame.")
        return
        
    x, y, w, h = cv2.boundingRect(head_c)
    
    print(f"Detected Head Bounds: x={x}, y={y}, w={w}, h={h}")
    
    # Now scan downwards from the head to find the black stick body
    # We will look at a narrow vertical strip below the head
    strip_x_start = x + w//2 - 2
    strip_x_end = x + w//2 + 2
    
    # Create a mask of dark pixels (the stick body)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, dark_mask = cv2.threshold(gray, 50, 255, cv2.THRESH_BINARY_INV)
    
    # Trace the body downwards
    body_pixels = []
    for cur_y in range(y + h, img.shape[0]):
        # Check if there are any dark pixels in this row within the strip
        if np.any(dark_mask[cur_y, strip_x_start:strip_x_end]):
            body_pixels.append(cur_y)
        elif len(body_pixels) > 0 and cur_y > body_pixels[-1] + 5:
            # If we found a gap of >5 pixels, we probably hit the ground or feet ended
            break
            
    if not body_pixels:
        print("Could not trace body below head.")
        return
        
    feet_y = max(body_pixels)
    total_body_height = feet_y - (y + h)
    
    print(f"Head bottom Y: {y+h}")
    print(f"Feet bottom Y: {feet_y}")
    print(f"Total Body Height (excluding head): {total_body_height} pixels")
    print(f"Head Size: {w}x{h} pixels")
    
    # Ratio:
    ratio = total_body_height / h if h > 0 else 0
    print(f"Ratio of Body to Head: {ratio:.2f}")

if __name__ == "__main__":
    analyze_proportions("youtube_frames_1080p/frame_0000.png")
    analyze_proportions("youtube_frames_1080p/frame_0010.png")
    analyze_proportions("youtube_frames_1080p/frame_0020.png")
