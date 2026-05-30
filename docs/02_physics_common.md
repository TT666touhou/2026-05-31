# 物理共通 (Physics Common)

## Verlet 積分系統 (`verlet_physics.gd`)
專案中不依賴純 Godot 內建的 `RigidBody2D` 關節來驅動生物肢體（因為在極端受力下會發生嚴重抖動與穿模），而是自定義了基於 Verlet Integration 的物理系統。
- **點與約束 (Points & Constraints)**：每個物理節點都是一個 Verlet Point，並透過距離約束（Distance Constraint）連接。
- **Swept Circle 碰撞檢測**：
  - 過去使用 Raycast 檢測會導致體積丟失穿牆。
  - 現在全面使用 Godot 的 `cast_motion` 與 `CircleShape2D` 進行連續碰撞檢測 (CCD)。
  - **重要參數**：每個點必須設定 `radius` 屬性。肢體半徑預設為 `5.0`，頭部半徑為 `8.0`。
  
## 碰撞層級 (Collision Layers)
- **Layer 1 (1)**: 靜態地形 (牆壁)。
- **Layer 2 (2)**: 玩家實體。
- **Layer 3 (4)**: 敵人實體。
- **Layer 4 (8)**: Hurtbox (受擊區)。
- **Layer 7 (64)**: 玩家武器攻擊判定區 (Hitbox)。
- **Layer 9 (256)**: 動態地形 (門、可推動物件)。

## 物理互動限制
- **嚴禁**：直接修改生物的 `RigidBody2D` transform 來進行位移，這會破壞物理引擎的內部狀態。
- **擊退處理**：對於使用 `CharacterBody2D` 的實體，受到擊退時應使用 `velocity = knockback_velocity` 直接覆蓋當前速度，並透過摩擦力遞減，避免速度每一幀指數疊加。
