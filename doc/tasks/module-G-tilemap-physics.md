# Module G: TileMap 原生實體碰撞 (Main.tscn)

- 移除過渡用的 `GroundBody`
- 在 TileSet 中開啟物理層 (Physics Layer 0)
- 為 `(2, 8)` 圖塊設定 `[-8,-8]` 到 `[8,8]` 的正方形碰撞
- 將所有資料直接存入 `Main.tscn` 且完全清除生成腳本
