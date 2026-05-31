import os
import re
import cv2
import numpy as np

# 1. Regenerate textures with NORMAL brightness (just crop and slight noise)
ART_DIR = r"C:\Users\88698\.gemini\antigravity-ide\brain\5256423d-c964-4269-8853-f9607cd814f9"
ASSETS_DIR = r"C:\Users\88698\Documents\2026.05.24\assets\textures\world"
west_raw = os.path.join(ART_DIR, "raw_room_west_1780218400139.png")
east_raw = os.path.join(ART_DIR, "raw_room_east_1780218415320.png")

def crop_texture(img_path, out_path, target_w, target_h):
    img = cv2.imread(img_path)
    if img is None:
        print(f"Failed to load {img_path}")
        return
    h, w = img.shape[:2]
    start_x = max(0, w//2 - target_w//2)
    start_y = max(0, h//2 - target_h//2)
    cropped = img[start_y:start_y+target_h, start_x:start_x+target_w]
    
    # Just add a very subtle high-frequency noise, DO NOT darken
    img_f = cropped.astype(np.float32) / 255.0
    noise = np.random.normal(0, 0.03, img_f.shape).astype(np.float32)
    img_final = np.clip(img_f + noise, 0, 1)
    
    out_img = (img_final * 255).astype(np.uint8)
    cv2.imwrite(out_path, out_img)
    print(f"Regenerated {out_path} with normal brightness.")

crop_texture(west_raw, os.path.join(ASSETS_DIR, "room_west_floor.png"), 816, 592)
crop_texture(east_raw, os.path.join(ASSETS_DIR, "room_east_floor.png"), 592, 400)

# 2. Create the post-processing shader
SHADER_DIR = r"C:\Users\88698\Documents\2026.05.24\src\world\atmosphere"
os.makedirs(SHADER_DIR, exist_ok=True)
shader_path = os.path.join(SHADER_DIR, "vision_fog.gdshader")
shader_code = """shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
    vec4 col = texture(screen_texture, SCREEN_UV);
    float luma = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    
    // Smooth transition from dark (unlit) to bright (lit by flashlight)
    // CanvasModulate is ~0.4, so unlit luma is ~0.2 to 0.4
    // Flashlight adds 0.8, so lit luma is > 0.8
    float factor = smoothstep(0.3, 0.65, luma);
    
    // The unlit fog color: desaturated and tinted slightly blue-gray
    vec3 fog_color = vec3(luma) * vec3(0.8, 0.85, 0.9);
    
    // Mix them
    COLOR.rgb = mix(fog_color, col.rgb, factor);
    COLOR.a = col.a;
}
"""
with open(shader_path, "w", encoding="utf-8") as f:
    f.write(shader_code)
print("Created vision_fog.gdshader")

# 3. Update CaveLevel.tscn
# Set CanvasModulate to 0.4
# Inject ColorRect into AtmosphereLayer
tscn_path = r"C:\Users\88698\Documents\2026.05.24\src\world\cave_01\CaveLevel.tscn"
with open(tscn_path, "r", encoding="utf-8") as f:
    content = f.read()

# Add shader ExtResource if not present
if "vision_fog.gdshader" not in content:
    res_str = '[ext_resource type="Shader" path="res://src/world/atmosphere/vision_fog.gdshader" id="100_shader"]\n'
    content = content.replace('[node name="CaveLevel"', res_str + '[node name="CaveLevel"')

# Modify CanvasModulate
content = re.sub(
    r'(\[node name="CanvasModulate" type="CanvasModulate".*?\ncolor = Color\()[^\)]+(\))',
    r'\g<1>0.4, 0.45, 0.5, 1\g<2>',
    content,
    flags=re.DOTALL
)

# Inject ColorRect into AtmosphereLayer if not present
if "VisionFogRect" not in content:
    fog_rect = """
[sub_resource type="ShaderMaterial" id="ShaderMaterial_fog"]
shader = ExtResource("100_shader")

[node name="VisionFogRect" type="ColorRect" parent="AtmosphereLayer"]
material = SubResource("ShaderMaterial_fog")
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
"""
    content = content.replace('[node name="CanvasModulate"', fog_rect + '\n[node name="CanvasModulate"')

with open(tscn_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Updated CaveLevel.tscn")
