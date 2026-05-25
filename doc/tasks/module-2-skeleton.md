# 模組二：骨架與物理重構 (Skeleton & Physics Remaster)

## 任務目標
依照《棒棒勇者大冒險》的長身比例重新定位骨骼，並調整加減速與 Jiggle 屬性以凸顯物理搖晃感。

## 實作細節
*   **控制器調整 (`player_controller.gd`)**: 
    *   將 `SPEED` 設為 `250.0`。
    *   將 `ACCEL` 設為 `3000.0`，`FRICTION` 設為 `2500.0`，製造極端加減速。
*   **骨骼座標定位 (`Player.tscn` 編輯)**:
    *   修改 `Bone2D` 的 `position` 屬性。
    *   `Spine`: `(0, -14)`
    *   `Head`: `(0, -8)`
    *   `Upper_Arm`: `(-6, -12)` 與 `(6, -12)` (相對於 Hips)
    *   `Lower_Arm`: `(0, 10)`
    *   `Upper_Leg`: `(-4, 2)` 與 `(4, 2)` (相對於 Hips)
    *   `Lower_Leg`: `(0, 10)`
*   **Jiggle 修改器設定**:
    *   修改所有 5 個 Jiggle 修改器的參數：`stiffness = 0.3`, `damping = 0.4`。
