# 模組三：空心方頭與程式化繪圖 (Procedural Drawing)

## 任務目標
將圓形實心大頭改為空心正方形，並確保所有線條為純白色且線寬一致，達成像素銳利風格。

## 實作細節
*   修改 `procedural_drawer.gd` 中的 `_draw()`。
*   **頭部**: 不再使用 `draw_circle`，改用 `draw_rect`。
    *   使用 `Rect2`，座標為 `Head` 骨骼的全局位置減去 `Vector2(5, 5)`，長寬為 `Vector2(10, 10)`。
    *   設定 `Color.WHITE`，`filled = false`，`width = 2.0`。
*   **四肢與軀幹**: 遍歷 Bone2D，使用 `draw_line` 連接父子節點，設定顏色為 `Color.WHITE`，`width = 2.0`。
