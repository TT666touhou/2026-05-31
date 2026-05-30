# Zombie

The Zombie (`Zombie.tscn` / `zombie.gd`) is the primary aggressive enemy.

## Behaviors & State Machine
- **IDLE**: The zombie stands still, applying friction to stop. It actively searches for a node in the `"player"` group within its `sight_range`.
- **CHASE**: Uses `NavigationAgent2D` to path towards the target player. Its `velocity` is explicitly overwritten by the pathing direction.
- **ATTACK**: When within attack range, the zombie lunges or bites. Its `HitboxComponent` is momentarily enabled to deal damage to the player.
- **DEAD**: Collision is disabled, rendering fades out or switches to a collapsed Verlet state.

## Physics Constraints
- The Zombie is built on `CharacterBody2D` with layer 4.
- Its `zombie_drawer.gd` establishes a robust Verlet rig with radius 8.0 for the head and 5.0 for the limbs, ensuring identical physical footprint to the Player.
- Knockback overrides the state machine's intended velocity to create genuine stuns.
