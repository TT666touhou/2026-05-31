# Godot Studio MCP Server — 安裝說明

MCP Server 已建立完成，需要手動一次性設定才能讓 Antigravity IDE 識別它。

## 方法 A：Antigravity IDE 設定 UI
在 IDE 中找到 Settings > MCP Servers，新增一個 Server：
- **Name**: `godot-studio`
- **Command**: `node`
- **Args**: `["C:\\Users\\88698\\Documents\\2026.05.24\\.mcp\\godot-studio-server\\server.js"]`

## 方法 B：直接執行測試
無論 IDE 是否識別，MCP Server 本身已完全可用。
在 PowerShell 中執行測試：
```powershell
cd C:\Users\88698\Documents\2026.05.24\.mcp\godot-studio-server
node server.js
```
應輸出：`✅ Godot Studio MCP Server running (stdio)`

## 提供的 4 個工具
- `run_gut_tests` — 執行 GUT 單元測試
- `capture_scene_screenshot` — headless 截圖場景
- `validate_gdscript` — 語法驗證 .gd 檔案
- `list_project_scenes` — 列出所有 .tscn 場景
