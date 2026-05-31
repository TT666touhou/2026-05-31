import cv2
import numpy as np
import os

# Define exact room sizes
WEST_ROOM_W, WEST_ROOM_H = 816, 592
EAST_ROOM_W, EAST_ROOM_H = 592, 400

# Artifact directory path
ART_DIR = r"C:\Users\88698\.gemini\antigravity-ide\brain\5256423d-c964-4269-8853-f9607cd814f9"
ASSETS_DIR = r"C:\Users\88698\Documents\2026.05.24\assets\textures\world"
os.makedirs(ASSETS_DIR, exist_ok=True)

# File paths
west_raw = os.path.join(ART_DIR, "raw_room_west_1780218400139.png")
east_raw = os.path.join(ART_DIR, "raw_room_east_1780218415320.png")

west_out = os.path.join(ASSETS_DIR, "room_west_floor.png")
east_out = os.path.join(ASSETS_DIR, "room_east_floor.png")

def process_room_texture(img_path, out_path, target_w, target_h, tint_color_bgr):
    # Load image
    img = cv2.imread(img_path)
    if img is None:
        print(f"Error loading {img_path}")
        return

    # Resize to something closer to the crop if it's too large, but 1024 is fine for 816x592
    h, w = img.shape[:2]
    
    # Crop from center
    start_x = max(0, w//2 - target_w//2)
    start_y = max(0, h//2 - target_h//2)
    img_cropped = img[start_y:start_y+target_h, start_x:start_x+target_w]

    # --- Darkwood Post-Processing Pipeline ---
    # 1. Convert to float32 for processing
    img_f = img_cropped.astype(np.float32) / 255.0

    # 2. Desaturate heavily (by 80%)
    hsv = cv2.cvtColor(img_cropped, cv2.COLOR_BGR2HSV).astype(np.float32)
    hsv[:, :, 1] *= 0.2  # Multiply saturation channel
    img_desat = cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2BGR).astype(np.float32) / 255.0

    # 3. Apply tint (Darkwood palette map)
    # tint_color is in BGR format [0-1]
    tint = np.array(tint_color_bgr, dtype=np.float32)
    # Multiply blend with tint
    img_tinted = img_desat * tint * 1.5 # Boost slightly to avoid making it pitch black
    img_tinted = np.clip(img_tinted, 0, 1)

    # 4. Add high-frequency noise
    noise = np.random.normal(0, 0.05, img_tinted.shape).astype(np.float32)
    img_noisy = np.clip(img_tinted + noise, 0, 1)

    # 5. Vignette / Ambient Occlusion towards the edges (room corners are darker)
    # Create a simple radial gradient mask
    X = np.linspace(-1, 1, target_w)
    Y = np.linspace(-1, 1, target_h)
    x, y = np.meshgrid(X, Y)
    dist = np.sqrt(x**2 + y**2)
    vignette = np.clip(1.2 - dist * 0.7, 0, 1)
    vignette = np.stack([vignette]*3, axis=-1)
    
    img_final = img_noisy * vignette

    # Convert back to uint8 and save
    out_img = (img_final * 255).astype(np.uint8)
    cv2.imwrite(out_path, out_img)
    print(f"Processed and saved: {out_path} ({target_w}x{target_h})")

# Darkwood palettes in BGR
west_tint = [0.12, 0.15, 0.18] # #2D1F12 in BGR approx, but let's use a dirty brown-grey -> B:0.12, G:0.15, R:0.18
east_tint = [0.15, 0.15, 0.14] # slightly greener/greyer -> B:0.15, G:0.15, R:0.14

process_room_texture(west_raw, west_out, WEST_ROOM_W, WEST_ROOM_H, west_tint)
process_room_texture(east_raw, east_out, EAST_ROOM_W, EAST_ROOM_H, east_tint)
