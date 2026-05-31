import re

with open("src/world/cave_01/CaveLevel.tscn", "r", encoding="utf-8") as f:
    content = f.read()

# Add ext_resources
if "room_west_floor.png" not in content:
    res_str = '[ext_resource type="Texture2D" path="res://assets/textures/world/room_west_floor.png" id="20_west"]\n[ext_resource type="Texture2D" path="res://assets/textures/world/room_east_floor.png" id="21_east"]\n'
    # insert before the first [node
    content = content.replace('[node name="CaveLevel"', res_str + '\n[node name="CaveLevel"')

# Remove FloorLayer completely. It matches from [node name="FloorLayer" up to the next [node
content = re.sub(r'\[node name="FloorLayer".*?(?=\n\[node)', '', content, flags=re.DOTALL)

# Insert the two Sprite2Ds
sprites = """[node name="WestRoomFloor" type="Sprite2D" parent="."]
z_index = -10
position = Vector2(8, 8)
texture = ExtResource("20_west")

[node name="EastRoomFloor" type="Sprite2D" parent="."]
z_index = -10
position = Vector2(712, 8)
texture = ExtResource("21_east")

"""
if "WestRoomFloor" not in content:
    content = content.replace('[node name="WallLayer"', sprites + '[node name="WallLayer"')

# Fix CanvasModulate color to be low-saturation dark grey
content = re.sub(
    r'(\[node name="CanvasModulate" type="CanvasModulate".*?\ncolor = Color\()[^\)]+(\))',
    r'\g<1>0.12, 0.12, 0.13, 1\g<2>',
    content,
    flags=re.DOTALL
)

with open("src/world/cave_01/CaveLevel.tscn", "w", encoding="utf-8") as f:
    f.write(content)

print("CaveLevel.tscn updated successfully.")
