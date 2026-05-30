# Vision and Lighting System

This project uses Godot 4's 2D lighting engine to simulate line-of-sight and directional flashlight mechanics.

## Environmental Lighting
- **CanvasModulate**: The level (`CaveLevel.tscn`) employs a `CanvasModulate` node set to a very dark tint (e.g., `Color(0.05, 0.05, 0.05)`). This serves as the global darkness, overriding the default bright 2D canvas.

## Player Lighting (Merged Texture)
To prevent the "blown-out" overexposure effect or color difference from overlapping lights, the player uses a **single merged texture** (`combined_flashlight.png`).
1. **Texture Generation**: The `flashlight_1.png` (cone) and `flashlight_2.png` (ambient circle) were perfectly merged using a MAX-blend script. This mathematically guarantees that the overlap is seamless and does not overexpose.
2. **VisionLight (`PointLight2D`)**: A single light source attached to the player uses this `combined_flashlight.png`. 
   - Because the texture's pivot center is exactly at the center of the ambient circle, rotating the `VisionLight` via `PlayerController.gd` causes the flashlight cone to track the mouse, while the ambient circle smoothly spins in place (which is invisible to the user).
   - This provides the highest performance and perfect shadow occlusion without any viewport overhead.

## Shadow Casters (Occluders)
- Dynamic shadows are achieved by ensuring all obstructing terrain (walls, doors, corners) feature a `LightOccluder2D` node.
- **Dynamic Occluders**: Modular pieces like `WallSegment` generate their `OccluderPolygon2D` dynamically in code based on their `grid_size` to ensure accurate shadow blocking.
- **Moving Occluders**: `WoodDoor` and `StoneDoor` disable their `LightOccluder2D` when opened, allowing light to pour into previously hidden rooms.

## Licensing
The lighting textures are sourced from [godotTestDemo](https://github.com/absolve/godotTestDemo) and are used under the MIT License (see `src/world/vision/godot3FlashLight_LICENSE.txt`).
