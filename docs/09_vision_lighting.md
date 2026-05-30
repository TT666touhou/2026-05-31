# Vision and Lighting System

This project uses Godot 4's 2D lighting engine to simulate line-of-sight and directional flashlight mechanics.

## Environmental Lighting
- **CanvasModulate**: The level (`CaveLevel.tscn`) employs a `CanvasModulate` node set to a very dark tint (e.g., `Color(0.05, 0.05, 0.05)`). This serves as the global darkness, overriding the default bright 2D canvas.

## Player Lighting (Procedural Generation)
To provide fully adjustable, seamless light overlap without overexposure, the player uses a **ProceduralLight** (`ProceduralLight.gd` extending `PointLight2D`).
1. **Dynamic Texture**: The script calculates an `Image` pixel-by-pixel using `max()` blending between an ambient circle and a flashlight cone. This ensures the overlap is mathematically perfect and prevents blowing out the brightness.
2. **Parameters**: The node exposes inspector variables (`ambient_radius`, `cone_angle`, etc.) that allow live adjustment in the editor.
3. **Rotation**: The pivot of the light is centered on the ambient circle. When `PlayerController.gd` rotates the `VisionLight` node, the cone tracks the mouse while the ambient circle spins in place seamlessly.

## Shadow Casters and Terrain Visibility
- **Unshaded Terrain**: Walls (`WallSegment`, `WallCorner`) and doors (`WoodDoor`, `StoneDoor`) use a `CanvasItemMaterial` set to `LIGHT_MODE_UNSHADED`. 
  - This ensures they ignore the global `CanvasModulate` darkness, keeping the maze layout always visible to the player at their natural colors.
- **Occluders**: Despite being visually unshaded, these objects still contain `LightOccluder2D` nodes. They cast dynamic shadows outward into the environment, successfully hiding floors, items, and enemies behind them in the darkness.
- **Dynamic Occluders**: Modular pieces like `WallSegment` generate their `OccluderPolygon2D` dynamically in code based on their `grid_size` to ensure accurate shadow blocking.
- **Moving Occluders**: `WoodDoor` and `StoneDoor` disable their `LightOccluder2D` when opened, allowing light to pour into previously hidden rooms.

## Licensing
The lighting textures are sourced from [godotTestDemo](https://github.com/absolve/godotTestDemo) and are used under the MIT License (see `src/world/vision/godot3FlashLight_LICENSE.txt`).
