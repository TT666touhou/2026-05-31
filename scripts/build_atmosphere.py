import os

vignette_shader = """shader_type canvas_item;
uniform float vignette_intensity = 0.8;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.9;
uniform vec4 vignette_rgb : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 uv = UV;
	uv -= 0.5;
	float dist = length(uv);
	float vignette = smoothstep(0.3, vignette_intensity, dist);
	COLOR = vec4(vignette_rgb.rgb, vignette * vignette_opacity);
}
"""

cave_content = """[gd_scene load_steps=10 format=3 uid="uid://cfy5b3m7qk2n3"]

[ext_resource type="Script" path="res://src/world/cave_01/cave_level.gd" id="1_cave"]
[ext_resource type="PackedScene" uid="uid://df7j1k2l3m4n5" path="res://src/entities/player/Player.tscn" id="2_player"]
[ext_resource type="TileSet" uid="uid://b1m7qk2n3v8d9" path="res://src/world/terrain_kit/DarkwoodTileSet.tres" id="3_tileset"]
[ext_resource type="PackedScene" uid="uid://barrel12345" path="res://src/world/props/PropBarrel.tscn" id="4_barrel"]
[ext_resource type="PackedScene" uid="uid://bookshelf123" path="res://src/world/props/PropBookshelf.tscn" id="5_bookshelf"]
[ext_resource type="Shader" path="res://src/world/atmosphere/vignette.gdshader" id="6_shader"]

[sub_resource type="ShaderMaterial" id="ShaderMaterial_vignette"]
shader = ExtResource("6_shader")
shader_parameter/vignette_intensity = 0.8
shader_parameter/vignette_opacity = 0.95
shader_parameter/vignette_rgb = Color(0, 0, 0, 1)

[node name="CaveLevel" type="Node2D"]
script = ExtResource("1_cave")

[node name="FloorLayer" type="TileMapLayer" parent="."]
z_index = -10
tile_set = ExtResource("3_tileset")

[node name="WallLayer" type="TileMapLayer" parent="."]
tile_set = ExtResource("3_tileset")

[node name="PropsLayer" type="Node2D" parent="."]
y_sort_enabled = true

[node name="PropBarrel" parent="PropsLayer" instance=ExtResource("4_barrel")]
position = Vector2(100, -50)

[node name="PropBarrel2" parent="PropsLayer" instance=ExtResource("4_barrel")]
position = Vector2(150, -40)

[node name="PropBookshelf" parent="PropsLayer" instance=ExtResource("5_bookshelf")]
position = Vector2(-120, -80)

[node name="Player" parent="." instance=ExtResource("2_player")]
position = Vector2(0, 0)

[node name="AtmosphereLayer" type="CanvasLayer" parent="."]

[node name="CanvasModulate" type="CanvasModulate" parent="AtmosphereLayer"]
color = Color(0.13, 0.13, 0.13, 1)

[node name="Vignette" type="ColorRect" parent="AtmosphereLayer"]
material = SubResource("ShaderMaterial_vignette")
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
"""

def build():
    atmo_dir = r"C:\Users\88698\Documents\2026.05.24\src\world\atmosphere"
    os.makedirs(atmo_dir, exist_ok=True)
    
    with open(os.path.join(atmo_dir, "vignette.gdshader"), 'w') as f:
        f.write(vignette_shader)
        
    cave_path = r"C:\Users\88698\Documents\2026.05.24\src\world\cave_01\CaveLevel.tscn"
    with open(cave_path, 'w', encoding='utf-8') as f:
        f.write(cave_content)
        
    print("Built Atmosphere and updated CaveLevel.")

if __name__ == "__main__":
    build()
