# 模組一：WASD 實體綁定 (Input Setup)

## 任務目標
徹底繞過 Godot 預設的方向鍵綁定，確保 `ui_left` 與 `ui_right` (或自訂的 `move_left`, `move_right`) 絕對支援 `KEY_A` 與 `KEY_D`。

## 實作細節
*   修改 `player_controller.gd` 的 `_ready()` 函式。
*   使用 `InputMap.has_action()` 檢查。
*   使用 `InputMap.add_action()` 新增動作。
*   使用 `InputEventKey` 設定 `keycode = KEY_A` (左) 與 `KEY_D` (右)，並用 `InputMap.action_add_event()` 註冊。
*   更新 `_physics_process` 中的 `Input.get_axis` 以對應新的 Action 名稱。
