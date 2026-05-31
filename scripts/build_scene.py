import os

tileset_content = """[gd_resource type="TileSet" load_steps=3 format=3 uid="uid://b1m7qk2n3v8d9"]

[ext_resource type="Texture2D" uid="uid://floor_stone" path="res://assets/textures/floor_stone_a.png" id="1_floor"]
[ext_resource type="Texture2D" uid="uid://wall_stone" path="res://assets/textures/wall_stone.png" id="2_wall"]

[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_floor"]
texture = ExtResource("1_floor")
texture_region_size = Vector2i(256, 256)
0:0/0 = 0

[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_wall"]
texture = ExtResource("2_wall")
texture_region_size = Vector2i(32, 32)
0:0/0 = 0
0:0/0/physics_layer_0/polygon_0/points = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
1:0/0 = 0
1:0/0/physics_layer_0/polygon_0/points = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
2:0/0 = 0
2:0/0/physics_layer_0/polygon_0/points = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
3:0/0 = 0
3:0/0/physics_layer_0/polygon_0/points = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
4:0/0 = 0
4:0/0/physics_layer_0/polygon_0/points = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
5:0/0 = 0
5:0/0/physics_layer_0/polygon_0/points = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
6:0/0 = 0
6:0/0/physics_layer_0/polygon_0/points = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
7:0/0 = 0
7:0/0/physics_layer_0/polygon_0/points = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
0:1/0 = 0
0:1/0/physics_layer_0/polygon_0/points = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
1:1/0 = 0
1:1/0/physics_layer_0/polygon_0/points = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
2:1/0 = 0
2:1/0/physics_layer_0/polygon_0/points = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
3:1/0 = 0
3:1/0/physics_layer_0/polygon_0/points = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
4:1/0 = 0
4:1/0/physics_layer_0/polygon_0/points = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
5:1/0 = 0
5:1/0/physics_layer_0/polygon_0/points = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
6:1/0 = 0
6:1/0/physics_layer_0/polygon_0/points = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)
7:1/0 = 0
7:1/0/physics_layer_0/polygon_0/points = PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)

[resource]
tile_size = Vector2i(32, 32)
physics_layer_0/collision_layer = 1
physics_layer_0/collision_mask = 0
sources/1 = SubResource("TileSetAtlasSource_floor")
sources/2 = SubResource("TileSetAtlasSource_wall")
"""

cave_content = """[gd_scene load_steps=5 format=3 uid="uid://cfy5b3m7qk2n3"]

[ext_resource type="Script" path="res://src/world/cave_01/cave_level.gd" id="1_cave"]
[ext_resource type="PackedScene" uid="uid://df7j1k2l3m4n5" path="res://src/entities/player/Player.tscn" id="2_player"]
[ext_resource type="TileSet" uid="uid://b1m7qk2n3v8d9" path="res://src/world/terrain_kit/DarkwoodTileSet.tres" id="3_tileset"]

[node name="CaveLevel" type="Node2D"]
script = ExtResource("1_cave")

[node name="FloorLayer" type="TileMapLayer" parent="."]
z_index = -10
tile_set = ExtResource("3_tileset")

[node name="WallLayer" type="TileMapLayer" parent="."]
tile_set = ExtResource("3_tileset")

[node name="PropsLayer" type="Node2D" parent="."]
y_sort_enabled = true

[node name="Player" parent="." instance=ExtResource("2_player")]
position = Vector2(0, 0)
"""

def build():
    # Save DarkwoodTileSet.tres
    ts_path = r"C:\Users\88698\Documents\2026.05.24\src\world\terrain_kit\DarkwoodTileSet.tres"
    with open(ts_path, 'w', encoding='utf-8') as f:
        f.write(tileset_content)
        
    # Read existing CaveLevel to extract any extra instances (like dummy, zombie, visionlight) if we want to preserve them,
    # but since we are doing a structural reset, just dropping in the player is cleaner. We can add enemies back.
    # Actually, let's keep it simple and just overwrite. The user wanted a clean slate modular structure.
    cave_path = r"C:\Users\88698\Documents\2026.05.24\src\world\cave_01\CaveLevel.tscn"
    with open(cave_path, 'w', encoding='utf-8') as f:
        f.write(cave_content)
        
    print("Successfully built Godot resources.")

if __name__ == "__main__":
    build()
