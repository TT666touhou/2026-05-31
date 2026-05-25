# 模組四：實證單元測試與驗收清單 (Empirical Testing)

## 任務目標
撰寫符合「實證驗證協定」的自動化測試，證明角色能夠真正移動且具備 Jiggle 效果。同時產出給使用者的最終驗收清單。

## 實作細節
*   **動態位移測試 (`test_movement.gd`)**:
    *   實例化 Player。
    *   利用 `Input.parse_input_event()` 送出 `KEY_A` 壓下的事件。
    *   跑迴圈 60 次呼叫 `_physics_process(1.0/60.0)`。
    *   斷言 `player.position.x < -40.0` (證明至少向左移動了 40 像素)。
*   **物理形變測試 (`test_skeleton.gd`)**:
    *   讓角色瞬間加速再瞬間煞車。
    *   在煞車初期的幾幀內，紀錄 `Head` 的 `global_position.x`。
    *   斷言它與其父節點的相對 X 軸不再為 0，證明它因為慣性發生了彎曲。
*   **玩家手動驗收清單 (Playtest Script)**: 
    *   直接寫在最後階段的 Prompt 回覆中，請玩家開啟遊戲照做。
