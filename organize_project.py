import os
import shutil

moves = {
    "Player.tscn": "entities/player/Player.tscn",
    "player_controller.gd": "entities/player/player_controller.gd",
    "procedural_drawer.gd": "entities/player/procedural_drawer.gd",
    "slime.tscn": "entities/slime/slime.tscn",
    "slime_controller.gd": "entities/slime/slime_controller.gd",
    "slime_drawer.gd": "entities/slime/slime_drawer.gd",
    "verlet_physics.gd": "physics/verlet/verlet_physics.gd",
    "verlet_pivot.gd": "physics/verlet/verlet_pivot.gd",
    "verlet_rig.gd": "physics/verlet/verlet_rig.gd",
    "verlet_strut.gd": "physics/verlet/verlet_strut.gd",
    "sword.tscn": "items/weapons/sword.tscn",
    "main.tscn": "levels/main.tscn",
    "Main.gd": "levels/Main.gd",
    "test_capture.gd": "tests/test_capture.gd",
    "test_slime_capture.gd": "tests/test_slime_capture.gd"
}

# Add some case-insensitive aliases that we know exist in code
replace_map = { f"res://{k}": f"res://{v}" for k, v in moves.items() }
replace_map["res://Main.tscn"] = "res://levels/main.tscn"

# Read all contents first
contents = {}
for file in moves.keys():
    if os.path.exists(file):
        with open(file, 'r', encoding='utf-8') as f:
            contents[file] = f.read()

# Replace paths in contents
for file, content in contents.items():
    new_content = content
    for old_path, new_path in replace_map.items():
        new_content = new_content.replace(old_path, new_path)
    contents[file] = new_content

# Move and write
for file, dest in moves.items():
    if not os.path.exists(file):
        print(f"Skipping {file} (not found)")
        continue
        
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    
    # Write the updated content to the new location
    with open(dest, 'w', encoding='utf-8') as f:
        f.write(contents[file])
        
    # Remove old file
    os.remove(file)
    print(f"Moved {file} -> {dest}")

print("Project organization complete!")
