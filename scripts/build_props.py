import os

prop_base_script = """extends StaticBody2D
class_name DarkwoodProp

# A simple base class for top-down physical props
"""

barrel_tscn = """[gd_scene load_steps=4 format=3 uid="uid://barrel12345"]

[ext_resource type="Script" path="res://src/world/props/PropBase.gd" id="1_script"]
[ext_resource type="Texture2D" uid="uid://barreltex" path="res://assets/textures/prop_barrel.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="CircleShape2D_1"]
radius = 30.0

[node name="PropBarrel" type="StaticBody2D"]
script = ExtResource("1_script")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_1")
"""

bookshelf_tscn = """[gd_scene load_steps=4 format=3 uid="uid://bookshelf123"]

[ext_resource type="Script" path="res://src/world/props/PropBase.gd" id="1_script"]
[ext_resource type="Texture2D" uid="uid://shelfrex" path="res://assets/textures/prop_bookshelf.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_1"]
size = Vector2(46, 94)

[node name="PropBookshelf" type="StaticBody2D"]
script = ExtResource("1_script")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_1")
"""

def build():
    props_dir = r"C:\Users\88698\Documents\2026.05.24\src\world\props"
    os.makedirs(props_dir, exist_ok=True)
    
    with open(os.path.join(props_dir, "PropBase.gd"), 'w') as f:
        f.write(prop_base_script)
        
    with open(os.path.join(props_dir, "PropBarrel.tscn"), 'w') as f:
        f.write(barrel_tscn)
        
    with open(os.path.join(props_dir, "PropBookshelf.tscn"), 'w') as f:
        f.write(bookshelf_tscn)
        
    print("Built Prop Scenes.")

if __name__ == "__main__":
    build()
