import cv2
import numpy as np
import os
from standardize_texture import process_image

def make_transparent(img):
    # Assume white or near-white background
    # Add alpha channel
    bgr = img[:, :, :3]
    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
    
    # Threshold for white background (very bright pixels)
    _, mask = cv2.threshold(gray, 240, 255, cv2.THRESH_BINARY_INV)
    
    # Find contours to keep only the largest object (ignore small noise)
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if contours:
        c = max(contours, key=cv2.contourArea)
        clean_mask = np.zeros_like(mask)
        cv2.drawContours(clean_mask, [c], -1, 255, -1)
        mask = clean_mask
        
    alpha = mask
    return np.dstack((bgr, alpha))

def crop_to_content(img):
    if img.shape[2] == 4:
        alpha = img[:,:,3]
        y_indices, x_indices = np.where(alpha > 0)
        if len(y_indices) > 0:
            min_y, max_y = np.min(y_indices), np.max(y_indices)
            min_x, max_x = np.min(x_indices), np.max(x_indices)
            return img[min_y:max_y+1, min_x:max_x+1]
    return img

def prepare_and_standardize():
    base_dir = r"C:\Users\88698\.gemini\antigravity-ide\brain\5256423d-c964-4269-8853-f9607cd814f9"
    out_dir = r"C:\Users\88698\Documents\2026.05.24\assets\textures"
    
    # Floor Stone
    floor_in = os.path.join(base_dir, "raw_floor_stone_1780199546719.png")
    if os.path.exists(floor_in):
        img = cv2.imread(floor_in, cv2.IMREAD_UNCHANGED)
        img = cv2.resize(img, (256, 256), interpolation=cv2.INTER_AREA)
        tmp_path = "tmp_floor.png"
        cv2.imwrite(tmp_path, img)
        process_image(tmp_path, os.path.join(out_dir, "floor_stone_a.png"), "seamless")
        
    # Wall Stone
    wall_in = os.path.join(base_dir, "raw_wall_stone_1780199569206.png")
    if os.path.exists(wall_in):
        img = cv2.imread(wall_in, cv2.IMREAD_UNCHANGED)
        # Crop center horizontal band to maintain aspect ratio 4:1
        h, w = img.shape[:2]
        center_y = h // 2
        band_h = w // 4
        img = img[center_y - band_h//2 : center_y + band_h//2, 0:w]
        img = cv2.resize(img, (256, 64), interpolation=cv2.INTER_AREA)
        tmp_path = "tmp_wall.png"
        cv2.imwrite(tmp_path, img)
        process_image(tmp_path, os.path.join(out_dir, "wall_stone.png"), "seamless")
        
    # Prop Barrel
    barrel_in = os.path.join(base_dir, "raw_prop_barrel_1780199582757.png")
    if os.path.exists(barrel_in):
        img = cv2.imread(barrel_in, cv2.IMREAD_UNCHANGED)
        if img.shape[2] == 3: img = make_transparent(img)
        img = crop_to_content(img)
        img = cv2.resize(img, (64, 64), interpolation=cv2.INTER_AREA)
        tmp_path = "tmp_barrel.png"
        cv2.imwrite(tmp_path, img)
        process_image(tmp_path, os.path.join(out_dir, "prop_barrel.png"), "prop")
        
    # Prop Bookshelf
    shelf_in = os.path.join(base_dir, "raw_prop_bookshelf_1780199597891.png")
    if os.path.exists(shelf_in):
        img = cv2.imread(shelf_in, cv2.IMREAD_UNCHANGED)
        if img.shape[2] == 3: img = make_transparent(img)
        img = crop_to_content(img)
        img = cv2.resize(img, (48, 96), interpolation=cv2.INTER_AREA)
        tmp_path = "tmp_shelf.png"
        cv2.imwrite(tmp_path, img)
        process_image(tmp_path, os.path.join(out_dir, "prop_bookshelf.png"), "prop")

if __name__ == "__main__":
    prepare_and_standardize()
