scene_data = """[gd_scene load_steps=4 format=3 uid="uid://cxw40d10q9q"]

[ext_resource type="Script" path="res://slime_controller.gd" id="1_controller"]
[ext_resource type="Script" path="res://slime_drawer.gd" id="2_drawer"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_1"]
size = Vector2(30, 20)

[node name="Slime" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_controller")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(0, -10)
shape = SubResource("RectangleShape2D_1")

[node name="SlimeDrawer" type="Node2D" parent="."]
script = ExtResource("2_drawer")
"""

with open("slime.tscn", "w", encoding="utf-8") as f:
    f.write(scene_data)
