import re

file_path = "src/world/cave_01/CaveLevel.tscn"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

sub_res = """[sub_resource type="ShaderMaterial" id="ShaderMaterial_fog"]
shader = ExtResource("100_shader")
"""

if sub_res in content:
    # remove it from current location
    content = content.replace(sub_res, "")
    # insert before [node name="CaveLevel"
    content = content.replace('[node name="CaveLevel"', sub_res + '\n[node name="CaveLevel"')
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Fixed CaveLevel.tscn formatting.")
else:
    print("sub_res not found or already fixed.")
