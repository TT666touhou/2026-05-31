# Player Architecture

The Player is a `CharacterBody2D` that combines standard Godot physics movement (`move_and_slide`) with a custom procedural rendering layer (`ProceduralDrawer`).

## Key Nodes & Modules
- **PlayerController (`PlayerController.gd`)**: The brain of the player. Handles:
  - Input parsing (WASD, Dash, Attacks).
  - Calling `move_and_slide()` based on `velocity`.
  - Inventory interactions (Equipping, Dropping).
  - Pushing RigidBody2Ds (Applies impulse to collided `RigidBody2D`s during `move_and_slide`).
- **ProceduralDrawer (`procedural_drawer.gd`)**: The visual representation.
  - Instantiates a `VerletPhysics` engine locally.
  - Sets up the skeletal structure (Head, Torso, Arms, Legs).
  - The Head has radius 8.0, the limbs have radius 5.0. This geometry is passed to the Verlet engine for volume collision.
  - Uses `_draw()` to render lines and circles using the integrated `VPoint` positions.
- **Weapon Controller**: When a weapon is equipped, it attaches a rig to the hand points in the `ProceduralDrawer`. 
- **Inventory System**: 
  - `InventoryManager` keeps track of `ItemData`.
  - `PlayerHUD` displays health, stamina, and mana using `ProgressBar`s.
  - `InventoryUI` is dynamically spawned for backpack interaction.

## Physics Synchronization
The Player's `CharacterBody2D` handles movement on the macro level, but the `ProceduralDrawer` simulates the physics of the limbs independently. The root of the Verlet rig (the Torso) is continuously driven toward the `CharacterBody2D`'s global position.
