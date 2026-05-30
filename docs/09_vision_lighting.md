# Vision and Lighting System

This project uses Godot 4's 2D lighting engine to simulate line-of-sight and directional flashlight mechanics.

## Environmental Lighting
- **CanvasModulate**: The level (`CaveLevel.tscn`) employs a `CanvasModulate` node set to a very dark tint (e.g., `Color(0.05, 0.05, 0.05)`). This serves as the global darkness, overriding the default bright 2D canvas.

## Player Lighting
The player is equipped with two light sources to provide a realistic exploration experience:
1. **Flashlight (Directional)**: A `PointLight2D` using a narrow beam texture (`flashlight_1.png`). In `PlayerController.gd`, this light is rotated every frame via `look_at(get_global_mouse_position())` to follow the player's aim.
2. **AmbientLight (Circular)**: A second `PointLight2D` using a circular texture (`flashlight_2.png`) providing a persistent aura of visibility around the player.

### Light Blending (Crucial)
- Both player lights are set to `blend_mode = 2` (**Mix**) instead of the default `Add`.
- This prevents severe overexposure (white blowout) in the areas where the circular ambient light overlaps with the directional flashlight beam.

## Shadow Casters (Occluders)
- Dynamic shadows are achieved by ensuring all obstructing terrain (walls, doors, corners) feature a `LightOccluder2D` node.
- **Dynamic Occluders**: Modular pieces like `WallSegment` generate their `OccluderPolygon2D` dynamically in code based on their `grid_size` to ensure accurate shadow blocking.
- **Moving Occluders**: `WoodDoor` and `StoneDoor` disable their `LightOccluder2D` when opened, allowing light to pour into previously hidden rooms.

## Licensing
The lighting textures are sourced from [godotTestDemo](https://github.com/absolve/godotTestDemo) and are used under the MIT License (see `src/world/vision/godot3FlashLight_LICENSE.txt`).
