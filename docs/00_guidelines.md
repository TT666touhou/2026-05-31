# Project Guidelines & Rules

## 1. Documentation Synchronization (MANDATORY)
**RULE:** Every time a modification is made to the codebase (adding a feature, changing architecture, refactoring logic), the corresponding markdown file in `docs/` MUST be updated to reflect the new state of the project.

- If a new system is added, create a new `docs/XX_system_name.md` file.
- If an existing system is modified, update the relevant `docs/` file before finishing the task.
- NEVER rely solely on the agent's internal memory. The `docs/` folder is the absolute source of truth for project structure and logic.

## 2. Physics & Kinematics
- Refer strictly to `docs/02_physics.md`. 
- No `RigidBody2D` should be used for limbs/actors. Use the custom swept-circle kinematic Verlet system.

## 3. UI & Inventory
- Refer to `docs/07_items.md`.
- Inventory is data-driven; weapons only become physical objects when instantiated into the procedural rig.
