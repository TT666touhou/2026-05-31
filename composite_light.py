import cv2
import numpy as np

def combine_lights():
    size = 512
    # Create empty black RGBA canvas
    canvas = np.zeros((size, size, 4), dtype=np.uint8)
    
    # Load images
    ambient = cv2.imread('src/world/vision/flashlight_2.png', cv2.IMREAD_UNCHANGED)
    flashlight = cv2.imread('src/world/vision/flashlight_1.png', cv2.IMREAD_UNCHANGED)
    
    if ambient is None or flashlight is None:
        print("Error: Could not load light textures.")
        return
        
    # Process Ambient: scale = 1.5
    h_a, w_a = ambient.shape[:2]
    new_w_a, new_h_a = int(w_a * 1.5), int(h_a * 1.5)
    ambient_scaled = cv2.resize(ambient, (new_w_a, new_h_a), interpolation=cv2.INTER_LINEAR)
    
    # Place Ambient centered at 256, 256
    x_offset_a = 256 - new_w_a // 2
    y_offset_a = 256 - new_h_a // 2
    
    # Add ambient to canvas (using max blending or simple alpha blending)
    # Since it's a light texture, we can just use the RGB channels and alpha channel
    for y in range(new_h_a):
        for x in range(new_w_a):
            cy = y + y_offset_a
            cx = x + x_offset_a
            if 0 <= cx < size and 0 <= cy < size:
                canvas[cy, cx] = np.maximum(canvas[cy, cx], ambient_scaled[y, x])
                
    # Process Flashlight: scale = 0.5, offset = 240 in X
    h_f, w_f = flashlight.shape[:2]
    new_w_f, new_h_f = int(w_f * 0.5), int(h_f * 0.5)
    flashlight_scaled = cv2.resize(flashlight, (new_w_f, new_h_f), interpolation=cv2.INTER_LINEAR)
    
    # Center is 256, 256. Offset is 240, 0. So position is 496, 256
    x_offset_f = 496 - new_w_f // 2
    y_offset_f = 256 - new_h_f // 2
    
    for y in range(new_h_f):
        for x in range(new_w_f):
            cy = y + y_offset_f
            cx = x + x_offset_f
            if 0 <= cx < size and 0 <= cy < size:
                canvas[cy, cx] = np.maximum(canvas[cy, cx], flashlight_scaled[y, x])
                
    cv2.imwrite('src/world/vision/combined_flashlight.png', canvas)
    print("Saved combined_flashlight.png")

if __name__ == '__main__':
    combine_lights()
