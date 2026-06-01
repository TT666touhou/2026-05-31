# generate_game_assets.py
import os
from PIL import Image, ImageDraw

# Create output folder
OUTPUT_DIR = "assets/generated_tiles"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Color Palettes
# Wood Floor
WF_BASE = (102, 87, 71, 255)       # #665747
WF_SHADOW = (78, 66, 54, 255)      # #4E4236
WF_HIGHLIGHT = (122, 104, 85, 255)  # #7A6855

# Wood Wall
WW_BASE = (77, 63, 50, 255)        # #4D3F32
WW_SHADOW = (59, 48, 38, 255)       # #3B3026
WW_HIGHLIGHT = (94, 78, 63, 255)   # #5E4E3F

# Stone Floor
SF_BASE = (74, 77, 84, 255)        # #4A4D54
SF_SHADOW = (56, 58, 63, 255)       # #383A3F
SF_HIGHLIGHT = (92, 95, 104, 255)  # #5C5F68

# Stone Wall
SW_BASE = (74, 64, 53, 255)        # #4A4035
SW_SHADOW = (54, 46, 39, 255)       # #362E27
SW_HIGHLIGHT = (94, 82, 68, 255)   # #5E5244

# Moss Overlay (used for variants)
MOSS_GREEN = (63, 82, 54, 200)     # #3F5236 with alpha

# Torch Colors
TORCH_WOOD = (140, 110, 74, 255)
TORCH_IRON = (115, 125, 140, 255)
FLAME_RED = (217, 65, 65, 255)
FLAME_ORANGE = (255, 138, 61, 255)
FLAME_YELLOW = (255, 209, 92, 255)

def create_base_img(transparent=False):
	if transparent:
		return Image.new("RGBA", (32, 32), (0, 0, 0, 0))
	return Image.new("RGBA", (32, 32), (0, 0, 0, 255))

# ── 1. Wood Floor Variations ────────────────────────────
def gen_wood_floors():
	# WF 0: Clean Planks
	im = create_base_img()
	draw = ImageDraw.Draw(im)
	draw.rectangle([0, 0, 31, 31], fill=WF_BASE)
	# Draw planks
	for y in [8, 16, 24]:
		draw.line([0, y, 31, y], fill=WF_SHADOW, width=1)
		draw.line([0, y - 1, 31, y - 1], fill=WF_HIGHLIGHT, width=1)
	im.save(os.path.join(OUTPUT_DIR, "wood_floor_0.png"))

	# WF 1: Nails in Planks
	im = create_base_img()
	draw = ImageDraw.Draw(im)
	draw.rectangle([0, 0, 31, 31], fill=WF_BASE)
	for y in [8, 16, 24]:
		draw.line([0, y, 31, y], fill=WF_SHADOW, width=1)
		draw.line([0, y - 1, 31, y - 1], fill=WF_HIGHLIGHT, width=1)
	# Draw nails at ends of boards
	for px in [4, 27]:
		for py in [4, 12, 20, 28]:
			draw.ellipse([px-1, py-1, px+1, py+1], fill=WF_SHADOW)
	im.save(os.path.join(OUTPUT_DIR, "wood_floor_1.png"))

	# WF 2: Cracked Plank
	im = create_base_img()
	draw = ImageDraw.Draw(im)
	draw.rectangle([0, 0, 31, 31], fill=WF_BASE)
	for y in [8, 16, 24]:
		draw.line([0, y, 31, y], fill=WF_SHADOW, width=1)
		draw.line([0, y - 1, 31, y - 1], fill=WF_HIGHLIGHT, width=1)
	# Jagged crack on the second plank
	draw.line([8, 12, 12, 10], fill=WF_SHADOW, width=1)
	draw.line([12, 10, 16, 14], fill=WF_SHADOW, width=1)
	draw.line([16, 14, 22, 11], fill=WF_SHADOW, width=1)
	im.save(os.path.join(OUTPUT_DIR, "wood_floor_2.png"))

	# WF 3: Mossy Plank
	im = create_base_img()
	draw = ImageDraw.Draw(im)
	draw.rectangle([0, 0, 31, 31], fill=WF_BASE)
	for y in [8, 16, 24]:
		draw.line([0, y, 31, y], fill=WF_SHADOW, width=1)
		draw.line([0, y - 1, 31, y - 1], fill=WF_HIGHLIGHT, width=1)
	# Draw moss blotches
	draw.ellipse([2, 2, 8, 7], fill=MOSS_GREEN)
	draw.ellipse([20, 18, 28, 25], fill=MOSS_GREEN)
	im.save(os.path.join(OUTPUT_DIR, "wood_floor_3.png"))

# ── 2. Wood Wall Variations ─────────────────────────────
def gen_wood_walls():
	# WW 0: Clean Vertical Planks
	im = create_base_img()
	draw = ImageDraw.Draw(im)
	draw.rectangle([0, 0, 31, 31], fill=WW_BASE)
	# Vertical lines
	for x in [8, 16, 24]:
		draw.line([x, 0, x, 31], fill=WW_SHADOW, width=1)
		draw.line([x - 1, 0, x - 1, 31], fill=WW_HIGHLIGHT, width=1)
	# Highlight top edge, shadow bottom edge
	draw.line([0, 0, 31, 0], fill=WW_HIGHLIGHT, width=1)
	draw.line([0, 31, 31, 31], fill=WW_SHADOW, width=1)
	im.save(os.path.join(OUTPUT_DIR, "wood_wall_0.png"))

	# WW 1: Supporting Crossbeam
	im = create_base_img()
	draw = ImageDraw.Draw(im)
	draw.rectangle([0, 0, 31, 31], fill=WW_BASE)
	for x in [8, 16, 24]:
		draw.line([x, 0, x, 31], fill=WW_SHADOW, width=1)
	# Diagonal beam
	draw.polygon([(4, 4), (27, 27), (27, 23), (8, 4)], fill=WW_HIGHLIGHT, outline=WW_SHADOW)
	im.save(os.path.join(OUTPUT_DIR, "wood_wall_1.png"))

	# WW 2: Damaged Planks
	im = create_base_img()
	draw = ImageDraw.Draw(im)
	draw.rectangle([0, 0, 31, 31], fill=WW_BASE)
	for x in [8, 16, 24]:
		draw.line([x, 0, x, 31], fill=WW_SHADOW, width=1)
		draw.line([x - 1, 0, x - 1, 31], fill=WW_HIGHLIGHT, width=1)
	# Broken plank hollow region
	draw.rectangle([10, 6, 14, 18], fill=WW_SHADOW)
	draw.line([9, 5, 11, 7], fill=WW_HIGHLIGHT, width=1)
	draw.line([13, 17, 15, 19], fill=WW_HIGHLIGHT, width=1)
	im.save(os.path.join(OUTPUT_DIR, "wood_wall_2.png"))

	# WW 3: Mossy Planks
	im = create_base_img()
	draw = ImageDraw.Draw(im)
	draw.rectangle([0, 0, 31, 31], fill=WW_BASE)
	for x in [8, 16, 24]:
		draw.line([x, 0, x, 31], fill=WW_SHADOW, width=1)
	# Moss crawling up
	draw.polygon([(0, 31), (8, 22), (16, 26), (24, 20), (31, 31)], fill=MOSS_GREEN)
	im.save(os.path.join(OUTPUT_DIR, "wood_wall_3.png"))

# ── 3. Stone Floor Variations ───────────────────────────
def gen_stone_floors():
	# SF 0: Clean Slab
	im = create_base_img()
	draw = ImageDraw.Draw(im)
	draw.rectangle([0, 0, 31, 31], fill=SF_BASE)
	# Grout borders
	draw.line([0, 0, 31, 0], fill=SF_HIGHLIGHT, width=1)
	draw.line([0, 0, 0, 31], fill=SF_HIGHLIGHT, width=1)
	draw.line([31, 0, 31, 31], fill=SF_SHADOW, width=1)
	draw.line([0, 31, 31, 31], fill=SF_SHADOW, width=1)
	im.save(os.path.join(OUTPUT_DIR, "stone_floor_0.png"))

	# SF 1: Cobblestones
	im = create_base_img()
	draw = ImageDraw.Draw(im)
	draw.rectangle([0, 0, 31, 31], fill=SF_SHADOW)
	# Draw individual cobblestones
	stones = [
		(3, 3, 12, 12), (15, 2, 28, 11),
		(2, 15, 14, 28), (17, 14, 29, 29)
	]
	for s in stones:
		draw.ellipse(s, fill=SF_BASE, outline=SF_HIGHLIGHT)
	im.save(os.path.join(OUTPUT_DIR, "stone_floor_1.png"))

	# SF 2: Cracked Slab
	im = create_base_img()
	draw = ImageDraw.Draw(im)
	draw.rectangle([0, 0, 31, 31], fill=SF_BASE)
	draw.line([0, 0, 31, 0], fill=SF_HIGHLIGHT, width=1)
	draw.line([0, 31, 31, 31], fill=SF_SHADOW, width=1)
	# Crack split
	draw.line([16, 0, 14, 10], fill=SF_SHADOW, width=1)
	draw.line([14, 10, 20, 18], fill=SF_SHADOW, width=1)
	draw.line([20, 18, 12, 31], fill=SF_SHADOW, width=1)
	im.save(os.path.join(OUTPUT_DIR, "stone_floor_2.png"))

	# SF 3: Mossy Slab
	im = create_base_img()
	draw = ImageDraw.Draw(im)
	draw.rectangle([0, 0, 31, 31], fill=SF_BASE)
	# Grout lines filled with moss
	draw.line([0, 0, 31, 0], fill=MOSS_GREEN, width=2)
	draw.line([0, 0, 0, 31], fill=MOSS_GREEN, width=2)
	draw.line([31, 0, 31, 31], fill=MOSS_GREEN, width=2)
	draw.line([0, 31, 31, 31], fill=MOSS_GREEN, width=2)
	# Little moss spots
	draw.ellipse([8, 8, 14, 13], fill=MOSS_GREEN)
	im.save(os.path.join(OUTPUT_DIR, "stone_floor_3.png"))

# ── 4. Stone Wall Variations ────────────────────────────
def gen_stone_walls():
	# SW 0: Standard Masonry Bricks
	im = create_base_img()
	draw = ImageDraw.Draw(im)
	draw.rectangle([0, 0, 31, 31], fill=SW_BASE)
	# Horizontal joints
	for y in [10, 21]:
		draw.line([0, y, 31, y], fill=SW_SHADOW, width=1)
		draw.line([0, y-1, 31, y-1], fill=SW_HIGHLIGHT, width=1)
	# Vertical joints
	draw.line([16, 0, 16, 10], fill=SW_SHADOW, width=1)
	draw.line([8, 11, 8, 21], fill=SW_SHADOW, width=1)
	draw.line([24, 11, 24, 21], fill=SW_SHADOW, width=1)
	draw.line([16, 22, 16, 31], fill=SW_SHADOW, width=1)
	im.save(os.path.join(OUTPUT_DIR, "stone_wall_0.png"))

	# SW 1: Large Blocks
	im = create_base_img()
	draw = ImageDraw.Draw(im)
	draw.rectangle([0, 0, 31, 31], fill=SW_BASE)
	# Cross grout lines
	draw.line([0, 16, 31, 16], fill=SW_SHADOW, width=2)
	draw.line([0, 15, 31, 15], fill=SW_HIGHLIGHT, width=1)
	draw.line([16, 0, 16, 31], fill=SW_SHADOW, width=2)
	draw.line([15, 0, 15, 31], fill=SW_HIGHLIGHT, width=1)
	im.save(os.path.join(OUTPUT_DIR, "stone_wall_1.png"))

	# SW 2: Cracked Masonry
	im = create_base_img()
	draw = ImageDraw.Draw(im)
	draw.rectangle([0, 0, 31, 31], fill=SW_BASE)
	# Bricks
	for y in [10, 21]:
		draw.line([0, y, 31, y], fill=SW_SHADOW, width=1)
	draw.line([16, 0, 16, 10], fill=SW_SHADOW, width=1)
	draw.line([8, 11, 8, 21], fill=SW_SHADOW, width=1)
	draw.line([16, 22, 16, 31], fill=SW_SHADOW, width=1)
	# Big jagged crack through bricks
	draw.line([4, 2, 8, 6], fill=SW_SHADOW, width=1)
	draw.line([8, 6, 6, 15], fill=SW_SHADOW, width=1)
	draw.line([6, 15, 14, 25], fill=SW_SHADOW, width=1)
	im.save(os.path.join(OUTPUT_DIR, "stone_wall_2.png"))

	# SW 3: Ivy/Moss Overgrown
	im = create_base_img()
	draw = ImageDraw.Draw(im)
	draw.rectangle([0, 0, 31, 31], fill=SW_BASE)
	for y in [10, 21]:
		draw.line([0, y, 31, y], fill=SW_SHADOW, width=1)
	# Ivy hanging down
	draw.polygon([(0, 0), (6, 14), (10, 4), (16, 18), (22, 5), (28, 12), (31, 0)], fill=MOSS_GREEN)
	im.save(os.path.join(OUTPUT_DIR, "stone_wall_3.png"))

# ── 5. Torch Animation (4 frames) ───────────────────────
# Enforce transparent background, consistent pixel art resolution (32x32)
def gen_torch_animation():
	# Frame 0: Medium flame leaning left
	im = create_base_img(transparent=True)
	draw = ImageDraw.Draw(im)
	# Bracket & Mount
	draw.rectangle([14, 18, 17, 31], fill=TORCH_WOOD)
	draw.rectangle([12, 18, 19, 21], fill=TORCH_IRON)
	# Flame shapes (Red -> Orange -> Yellow)
	draw.polygon([(10, 18), (14, 5), (19, 18)], fill=FLAME_RED)
	draw.polygon([(12, 18), (14, 9), (17, 18)], fill=FLAME_ORANGE)
	draw.polygon([(13, 18), (15, 12), (16, 18)], fill=FLAME_YELLOW)
	im.save(os.path.join(OUTPUT_DIR, "torch_0.png"))

	# Frame 1: Large flame flickering up
	im = create_base_img(transparent=True)
	draw = ImageDraw.Draw(im)
	draw.rectangle([14, 18, 17, 31], fill=TORCH_WOOD)
	draw.rectangle([12, 18, 19, 21], fill=TORCH_IRON)
	draw.polygon([(11, 18), (15, 2), (20, 18)], fill=FLAME_RED)
	draw.polygon([(13, 18), (15, 6), (18, 18)], fill=FLAME_ORANGE)
	draw.polygon([(14, 18), (16, 10), (17, 18)], fill=FLAME_YELLOW)
	im.save(os.path.join(OUTPUT_DIR, "torch_1.png"))

	# Frame 2: Medium flame leaning right
	im = create_base_img(transparent=True)
	draw = ImageDraw.Draw(im)
	draw.rectangle([14, 18, 17, 31], fill=TORCH_WOOD)
	draw.rectangle([12, 18, 19, 21], fill=TORCH_IRON)
	draw.polygon([(12, 18), (17, 5), (21, 18)], fill=FLAME_RED)
	draw.polygon([(14, 18), (17, 9), (19, 18)], fill=FLAME_ORANGE)
	draw.polygon([(15, 18), (16, 12), (18, 18)], fill=FLAME_YELLOW)
	im.save(os.path.join(OUTPUT_DIR, "torch_2.png"))

	# Frame 3: Smaller intense flame
	im = create_base_img(transparent=True)
	draw = ImageDraw.Draw(im)
	draw.rectangle([14, 18, 17, 31], fill=TORCH_WOOD)
	draw.rectangle([12, 18, 19, 21], fill=TORCH_IRON)
	draw.polygon([(11, 18), (15, 8), (20, 18)], fill=FLAME_RED)
	draw.polygon([(13, 18), (15, 11), (18, 18)], fill=FLAME_ORANGE)
	draw.polygon([(14, 18), (15, 13), (17, 18)], fill=FLAME_YELLOW)
	im.save(os.path.join(OUTPUT_DIR, "torch_3.png"))

if __name__ == "__main__":
	print("--- GENERATING STANDARDIZED GAME ASSETS (32x32, RGBA) ---")
	gen_wood_floors()
	gen_wood_walls()
	gen_stone_floors()
	gen_stone_walls()
	gen_torch_animation()
	print("Successfully generated all assets in:", OUTPUT_DIR)

	# Create a stitched showcase preview sheet
	preview = Image.new("RGBA", (32 * 4, 32 * 5), (40, 42, 46, 255)) # Dark background
	for row, category in enumerate(["wood_floor", "wood_wall", "stone_floor", "stone_wall", "torch"]):
		for col in range(4):
			filename = f"{category}_{col}.png"
			img_path = os.path.join(OUTPUT_DIR, filename)
			if os.path.exists(img_path):
				tile = Image.open(img_path)
				# Paste with transparency mask
				preview.paste(tile, (col * 32, row * 32), tile)

	# Scale by 4x using nearest neighbor to make it easy to see
	preview_scaled = preview.resize((32 * 4 * 4, 32 * 5 * 4), Image.NEAREST)
	preview_path = os.path.join(OUTPUT_DIR, "showcase_preview.png")
	preview_scaled.save(preview_path)
	print("Generated stitched showcase preview at:", preview_path)

