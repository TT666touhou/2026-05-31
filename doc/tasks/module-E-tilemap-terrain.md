# Module E: 原生場景內建 TileMap

## 目標
將 Kenney 的圖塊直接寫入 `.tscn` 檔案中，完全不需要在執行期依賴外掛腳本。

## 內容
- 建立並執行 Godot 工具腳本 `build_tilemap.gd`
- 自動開啟 `Main.tscn`，配置 `TileMapLayer`，寫入 160 塊地面圖塊
- 將修改後的資料直接儲存回 `Main.tscn` (包含 TileSet 和二進位的 tile_map_data)
- 刪除生成腳本，讓專案保持最乾淨的狀態。
