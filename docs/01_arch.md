# Architecture Core

This project uses a Component-based architecture within Godot 4.6.

## Component System
- Entities (Player, Enemies) are built using standard CharacterBody2D nodes, but their core stats and interactions are abstracted into decoupled Node or Area2D components.
- **HealthComponent**: Manages HP, handles damage, emits health_changed and died signals.
- **StaminaComponent / ManaComponent**: Manages resources for attacks and abilities.
- **HurtboxComponent**: Area2D that receives damage (listens for intersections with Hitboxes). Defines the vulnerable body.
- **HitboxComponent**: Area2D that deals damage to overlapping Hurtboxes. Handles continuous damage, knockback vectors, and ignores its own owner.

## Physics & Layers
- Layer 1: Terrain / Static bodies
- Layer 2: Player
- Layer 3: Enemies
- Layer 4: Player Hurtbox (mask: 6 - Enemy Hitbox)
- Layer 5: Player Hitbox (mask: 5 - Enemy Hurtbox)
- Layer 6: Enemy Hurtbox
- Layer 7: Enemy Hitbox

## Rendering & Rigging
- Standard sprite rendering is avoided for organic characters. Instead, ProceduralDrawer scripts utilize the custom VerletPhysics engine to calculate skeletal joints dynamically.
- _draw() is heavily utilized for rendering primitives (lines, circles) across characters and weapons, keeping the art pipeline 100% procedural.