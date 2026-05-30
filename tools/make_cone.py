import math
from PIL import Image

size = 1024
img = Image.new('RGBA', (size, size), (0,0,0,0))
pixels = img.load()
cx, cy = size//2, size//2
max_radius = size//2

fov = 100 # slightly wider than 90 to allow fading
half_fov = fov / 2.0

for y in range(size):
    for x in range(size):
        dx = x - cx
        dy = y - cy
        dist = math.sqrt(dx*dx + dy*dy)
        if dist <= max_radius:
            angle = math.degrees(math.atan2(dy, dx))
            # Normalize angle to -180 to 180
            if angle > 180: angle -= 360
            if angle < -180: angle += 360
            
            if abs(angle) <= half_fov:
                # Radial fade
                alpha = 255 * (1.0 - (dist / max_radius)**2)
                # Angular fade at the edges (last 10 degrees)
                angular_fade = 1.0
                edge_dist = half_fov - abs(angle)
                if edge_dist < 10:
                    angular_fade = edge_dist / 10.0
                
                final_alpha = int(alpha * angular_fade)
                pixels[x, y] = (255, 255, 255, final_alpha)

import os
os.makedirs('src/world/vision', exist_ok=True)
img.save('src/world/vision/light_cone.png')
print('light_cone.png created')
