import cv2
import numpy as np
import argparse
import sys

def build_darkwood_lut():
    # Define keypoints in BGR format
    # Darkwood has very muted, desaturated, dark tones.
    # We map Luma (0-255) to these BGR values.
    # Luma 0 -> #0a0a0a
    # Luma 85 -> #1e1c18 (B=24, G=28, R=30)
    # Luma 170 -> #2d271d (B=29, G=39, R=45)
    # Luma 255 -> #4b463e (B=62, G=70, R=75)
    
    luma_points = [0, 85, 170, 255]
    b_points = [10, 24, 29, 62]
    g_points = [10, 28, 39, 70]
    r_points = [10, 30, 45, 75]
    
    lut = np.zeros((256, 1, 3), dtype=np.uint8)
    for i in range(256):
        b = np.interp(i, luma_points, b_points)
        g = np.interp(i, luma_points, g_points)
        r = np.interp(i, luma_points, r_points)
        lut[i, 0, 0] = int(b)
        lut[i, 0, 1] = int(g)
        lut[i, 0, 2] = int(r)
    return lut

def add_noise(img, intensity=10):
    noise = np.random.normal(0, intensity, img.shape).astype(np.float32)
    noisy_img = cv2.add(img.astype(np.float32), noise)
    return np.clip(noisy_img, 0, 255).astype(np.uint8)

def apply_vignette(img, alpha_mask):
    # Apply vignette only to the opaque areas
    rows, cols = img.shape[:2]
    
    # Calculate bounds of the actual opaque object
    y_indices, x_indices = np.where(alpha_mask > 0)
    if len(y_indices) == 0:
        return img
        
    min_y, max_y = np.min(y_indices), np.max(y_indices)
    min_x, max_x = np.min(x_indices), np.max(x_indices)
    
    center_y = (min_y + max_y) / 2.0
    center_x = (min_x + max_x) / 2.0
    
    max_dist = np.sqrt(((max_y - min_y)/2.0)**2 + ((max_x - min_x)/2.0)**2)
    if max_dist == 0:
        max_dist = 1
        
    y, x = np.ogrid[:rows, :cols]
    dist = np.sqrt((x - center_x)**2 + (y - center_y)**2)
    
    # Gradient: 1.0 at center, drops to 0.4 at edges
    vignette = 1.0 - (dist / max_dist) * 0.6
    vignette = np.clip(vignette, 0.4, 1.0)
    
    img_float = img.astype(np.float32)
    for c in range(3):
        img_float[:,:,c] = img_float[:,:,c] * vignette
        
    return np.clip(img_float, 0, 255).astype(np.uint8)

def process_image(input_path, output_path, img_type):
    # Read image with alpha channel
    img = cv2.imread(input_path, cv2.IMREAD_UNCHANGED)
    if img is None:
        print(f"Error: Could not read {input_path}")
        sys.exit(1)
        
    has_alpha = img.shape[2] == 4
    if has_alpha:
        bgr = img[:,:,:3]
        alpha = img[:,:,3]
    else:
        bgr = img
        alpha = np.full((img.shape[0], img.shape[1]), 255, dtype=np.uint8)
        
    # 1. Normalize histogram (stretch contrast of original before re-mapping)
    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
    gray = cv2.normalize(gray, None, alpha=0, beta=255, norm_type=cv2.NORM_MINMAX)
    gray3 = cv2.merge([gray, gray, gray])
    
    # 2. Map to Darkwood LUT
    lut = build_darkwood_lut()
    mapped = cv2.LUT(gray3, lut)
    
    # 3. Add global uniform noise
    noisy = add_noise(mapped, intensity=8)
    
    # 4. Vignette (only for props, not seamless tiles)
    if img_type == 'prop':
        final_bgr = apply_vignette(noisy, alpha)
    else:
        final_bgr = noisy
        
    # Combine back with alpha
    if has_alpha:
        final_img = np.dstack((final_bgr, alpha))
    else:
        # Save as 32-bit ARGB anyways to prevent headless Godot corruption
        final_img = np.dstack((final_bgr, alpha))
        
    cv2.imwrite(output_path, final_img)
    print(f"Successfully processed {input_path} -> {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Standardize texture for Darkwood style.")
    parser.add_argument("input", help="Input image path")
    parser.add_argument("output", help="Output image path")
    parser.add_argument("--type", choices=['seamless', 'prop'], default='seamless', help="Type of asset (prop applies vignette)")
    args = parser.parse_args()
    
    process_image(args.input, args.output, args.type)
