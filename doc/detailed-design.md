# 詳細技術設計：距離匹配相位與 IK 行走系統

## 1. 物理重構 (procedural_drawer.gd)

### 1.1 相位計算
導入基於 X 座標的相位追蹤：
```gdscript
const STRIDE_LENGTH = 32.0  # 完整跨步的距離

# 將絕對 X 座標轉換為 0~1 的相位
var global_phase = fposmod(character_body.global_position.x / STRIDE_LENGTH, 1.0)
```

### 1.2 左右腳相位分配
```gdscript
# 左右腳永遠相差 180 度 (0.5 相位)
var l_phase = global_phase
var r_phase = fposmod(global_phase + 0.5, 1.0)
```

### 1.3 分段步態函數 (Piecewise Gait Function)
利用相位計算出腳相對於骨盆的 X 與 Y 偏移量。
```gdscript
func calculate_foot_offset(phase: float, stride: float) -> Vector2:
    if phase < 0.5:
        # 支撐期 (Stance)：腳貼在地上，從前方往後退
        # 當 phase 從 0 -> 0.5 時，X 從 stride/2 -> -stride/2
        var t = phase * 2.0  # 0 -> 1
        var x = lerp(stride / 2.0, -stride / 2.0, t)
        return Vector2(x, 0.0)
    else:
        # 擺盪期 (Swing)：抬腳往前跨
        # 當 phase 從 0.5 -> 1.0 時，X 從 -stride/2 -> stride/2
        var t = (phase - 0.5) * 2.0 # 0 -> 1
        var x = lerp(-stride / 2.0, stride / 2.0, t)
        var y = -sin(t * PI) * STEP_HEIGHT
        return Vector2(x, y)
```

### 1.4 套用與 IK 解算
算出 `l_foot_target` 與 `r_foot_target` 後，如同上一版的設計，利用二節點 IK (`_solve_ik`) 算出膝蓋座標。
由於腳在「支撐期」往後退的速度與角色往前進的速度完全抵銷，腳的世界座標將維持靜止，形成完美的釘腳效果。

## 2. 骨盆與頭部連動
- 當 `global_phase` 接近 $0.0$ 或 $0.5$（腳張最開），骨盆需要下降。
- 當 `global_phase` 接近 $0.25$ 或 $0.75$（兩腳交會），骨盆需要上升。
這可以用一個簡單的 $| \sin(\text{phase} \times 2\pi) |$ 曲線來完美模擬。

## 3. 手臂連動
手臂擺動直接反向對應腳的偏移，無需額外的時間變數，保證手腳協調。

## 4. 驗證計畫
1. 觀察角色站立時，雙腳是否保持靜止。
2. 按下 D 向右走時，支撐腳是否像被釘在地板上一樣完全不滑動。
3. 觀察雙腳是否有明顯的「交叉錯開」，而非小碎步。
4. 突然變換方向時，腳步是否能無縫反向跨出，沒有抖動。
