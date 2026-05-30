# Puppet (Dummy)

The Dummy (`Dummy.tscn` / `dummy.gd`) is a stationary target used primarily for testing weapon hitboxes, damage numbers, and knockback forces.

## Key Features
- **Root Node**: `StaticBody2D`. Unlike the Player or Zombie, the dummy does not move around the world, so it doesn't need a `CharacterBody2D`.
- **HurtboxComponent**: Handles incoming damage. When hit, it takes damage and applies a visual "squish" effect or localized physics impulse.
- **Physics**: Uses a highly relaxed `VerletPhysics` rig that is anchored to the ground but allows the torso and head to wobble when struck. 
- **Purpose**: Serves as the purest example of the procedural rendering and physics reaction without the complexities of AI state machines.
