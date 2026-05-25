# 執行 Prompt：實作相位驅動 IK 行走

你是 Godot 4 專業代理。依序完成以下模組。

## MODULE G: Phase-Driven IK Locomotion
- 開啟 `procedural_drawer.gd`。
- 刪除舊的 `l_step_t`, `r_step_t`, `ideal_l`, `ideal_r` 等拼湊的步態邏輯。
- 引入基於角色絕對 `global_position.x` 的相位 `global_phase` 計算。
- 實作分段函數，正確分割 0~0.5 支撐期與 0.5~1.0 擺盪期，並給予對應的 $X$ 與 $Y$ 位移。
- 確保左右腳相位相差 0.5。
- 實作完畢後更新任務狀態。
