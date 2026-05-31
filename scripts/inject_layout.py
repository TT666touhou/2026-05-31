import json
import re

with open("layout_data.json", "r") as f:
    data = json.load(f)

floor_b64 = data["floor"]
wall_b64 = data["wall"]

with open("src/world/cave_01/CaveLevel.tscn", "r", encoding="utf-8") as f:
    content = f.read()

# Replace floor tile_map_data
content = re.sub(
    r'(\[node name="FloorLayer".*?tile_map_data = PackedByteArray\(").*?("\))',
    rf'\g<1>{floor_b64}\g<2>',
    content,
    flags=re.DOTALL
)

# Replace wall tile_map_data
content = re.sub(
    r'(\[node name="WallLayer".*?tile_map_data = PackedByteArray\(").*?("\))',
    rf'\g<1>{wall_b64}\g<2>',
    content,
    flags=re.DOTALL
)

# Fix CanvasModulate color (so it's not pitch black)
content = re.sub(
    r'(\[node name="CanvasModulate" type="CanvasModulate".*?)\ncolor = Color\([^\)]+\)',
    r'\1\ncolor = Color(0.13, 0.13, 0.13, 1)',
    content,
    flags=re.DOTALL
)

with open("src/world/cave_01/CaveLevel.tscn", "w", encoding="utf-8") as f:
    f.write(content)

print("Injected tile map data and fixed CanvasModulate into CaveLevel.tscn successfully.")
