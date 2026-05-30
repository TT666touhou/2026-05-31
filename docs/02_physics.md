# Physics System (Shared)

This project relies on a custom Verlet integration system rather than Godot's built-in `RigidBody2D` nodes for character rigs. This is to maintain strict control over IK (Inverse Kinematics), constraint lengths, and procedural animation quality. 
**NEVER** replace Verlet points with `RigidBody2D` for organic character limbs, as it will lead to jittering ("spaghettification") when constrained.

## VerletPhysics (`verlet_physics.gd`)
A standalone Verlet integrator that processes constraints and handles world collisions.

### Key Concepts
- **VPoint**: A node/particle in the physics simulation. 
  - `pos` and `old_pos` determine velocity implicitly.
  - `radius`: Crucial for collision volume. Ensure this matches the visual/Hurtbox radius.
- **VStick**: A distance constraint between two `VPoint`s. Restricts stretch.
- **VAntiFlip**: A constraint that prevents angular inversion (knees bending backward). Ensures a defined cross-product sign is maintained across 3 points.
- **VMotor**: Drives a point towards a target position using a defined stiffness. Used for hands tracking mouse targets or feet tracking the floor.

### Swept-Circle Collision (`cast_motion`)
- Previous implementations used `intersect_ray` which resulted in infinitely thin collision lines.
- We have upgraded to `cast_motion` using `PhysicsShapeQueryParameters2D` with a `CircleShape2D`.
- This ensures points have volume and cannot phase through walls or doors, especially at high velocities or when pushed into corners.
- **Restitution & Slide**: When a point hits terrain, it slides along the normal (`remaining_motion.slide(normal)`) and pushes the terrain back if the terrain is a `RigidBody2D`.
