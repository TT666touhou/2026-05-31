from PIL import Image, ImageDraw
import math

size = 1024
img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Center is at left middle (0, 512)
center = (0, 512)
radius = 1000

# Draw a 90 degree cone (-45 to 45) facing right
# PIL angles are 0 = right, goes clockwise
start_angle = -45
end_angle = 45

draw.pieslice([center[0]-radius, center[1]-radius, center[0]+radius, center[1]+radius], start_angle, end_angle, fill=(255,255,255,255))

# Optional: apply soft blur for soft light edges
from PIL import ImageFilter
img = img.filter(ImageFilter.GaussianBlur(10))

img.save('C:/Users/88698/Documents/2026.05.24/src/world/vision/light_cone.png')
