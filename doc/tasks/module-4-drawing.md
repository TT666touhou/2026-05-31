# Module 4: 程式化動態繪圖 (Procedural Drawing)

- [x] 在 `Player.tscn` 內建立一個 `Node2D` (命名為 `ProceduralDrawer`)。
- [x] 為 `ProceduralDrawer` 建立並掛載腳本 `procedural_drawer.gd`。
- [x] 實作 `_process()` 讀取 `Skeleton2D` 內所有 `Bone2D` 的 Transform 座標。
- [x] 實作 `_draw()` 函數：
  - [x] 用 `draw_line()` 將骨骼連線畫出火柴人身體。
  - [x] 用 `draw_circle()` 畫出實心頭部。
