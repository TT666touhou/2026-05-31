# Items & Inventory

The inventory system is decoupled from the player's physical body, acting purely on data structures until an item is physically held (equipped) or dropped.

## Data Structures
- **ItemData**: A `Resource` that holds the item's `id`, `item_name`, `grid_size`, `icon_lines` (for procedural UI rendering), `weapon_scene` (the packed scene that will be instantiated when equipped), and `stamina_cost`.
- **InventoryManager**: A `Node` attached to the Player that maintains the grid inventory array and a fixed size `hotbar_items` array (size 4). It handles logic for picking up (`auto_add_to_backpack`), moving items, and dropping them.

## User Interface
- **InventoryUI**: Draws a grid-based backpack interface. It reads `icon_lines` from `ItemData` and dynamically renders the item icons in the UI grid using `_draw()`, maintaining the procedural aesthetic.
- **PlayerHUD**: Displays the current hotbar selection and the player's vitals.

## Weapon Rigs
When an item is equipped (via Hotbar selection), the `weapon_scene` is instantiated and passed to the `ProceduralDrawer`.
- **Weapon Controller**: Each weapon scene (e.g., `sword.tscn`, `bow.tscn`) has a controller script that defines IK targets for the player's hands. It handles the attack animation phases (anticipation, strike, recovery) by manipulating `VMotor` target functions in the player's Verlet engine.
