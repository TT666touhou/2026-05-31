# Terrain & World

The environment is built using modular 2D scenes that snap together to form dungeon layouts.

## Terrain Pieces
- **TerrainPiece (`TerrainPiece.gd`)**: The base class for walls, floors, and corners. All static structures inherit from this. It standardizes sizes and collision layers.
- **Collision**: Terrain is on Collision Layer 1 (Static).

## Interactables & RigidBodies
To maintain a highly physical and interactive world, small props and unlocked doors utilize Godot's `RigidBody2D`.
- **WoodTable (`WoodTable.tscn`)**: A RigidBody2D that can be pushed by players and enemies.
- **WoodDoor (`WoodDoor.tscn`)**: A hinged RigidBody2D. The player pushes it open simply by walking into it.
- **Player Interaction**: The `PlayerController` detects collisions with `RigidBody2D` during `move_and_slide()` and applies an impulse (`apply_impulse`) based on the collision normal and offset, allowing for realistic leverage (pushing the edge of a door makes it swing faster).
