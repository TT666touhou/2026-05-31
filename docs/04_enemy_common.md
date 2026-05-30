# Enemy Common Architecture

Enemies in this project follow a shared structural pattern utilizing `CharacterBody2D` for root movement and state machines for AI.

## Core Structure
- **CharacterBody2D**: Handles wall collisions and `move_and_slide()`.
- **NavigationAgent2D**: Used for pathfinding. The agent calculates the next path position, and the enemy sets its velocity towards that point.
- **State Machine**: Logic is divided into distinct states (e.g., `IDLE`, `CHASE`, `ATTACK`, `DEAD`).
- **Procedural Drawer**: Enemies use similar procedural rendering scripts to the Player, instantiating their own `VerletPhysics` engine for limb movement and reaction.

## Combat Interactions
- **Targeting**: Enemies locate targets via `get_tree().get_nodes_in_group("player")`.
- **HurtboxComponent**: Attached to the enemy body. When a player's `HitboxComponent` overlaps this, it takes damage and applies knockback.
- **HitboxComponent**: The enemy's attack volume (e.g., a Zombie bite). It deals continuous damage on intervals if the player stays within it.
- **Knockback Handling**: Knockback is NOT accumulated over frames. `knockback_velocity` explicitly overrides the AI's intended velocity until friction scales it down to zero, acting as a genuine stun/pushback effect.
