# Module B: procedural_drawer.gd 全面重寫

## 目標
用純 GDScript 彈簧質點系統取代一切 Skeleton2D 相關邏輯，同時精確還原棒棒勇者外型。

## 原子任務清單

### B-1: 常數與資料結構定義
- [ ] 定義 11 個質點的索引 enum：`HIPS, SPINE_TOP, HEAD_CENTER, L_ELBOW, L_HAND, R_ELBOW, R_HAND, L_KNEE, L_FOOT, R_KNEE, R_FOOT`
- [ ] 定義 `REST_OFFSETS: Array[Vector2]`，值依設計文件精確填入：
  ```
  HIPS:        Vector2(  0,   0)
  SPINE_TOP:   Vector2(  0, -20)
  HEAD_CENTER: Vector2(  0, -31)
  L_ELBOW:     Vector2(-10, -20)
  L_HAND:      Vector2(-10, -10)
  R_ELBOW:     Vector2( 10, -20)
  R_HAND:      Vector2( 10, -10)
  L_KNEE:      Vector2( -5,  10)
  L_FOOT:      Vector2( -3,  22)
  R_KNEE:      Vector2(  5,  10)
  R_FOOT:      Vector2(  3,  22)
  ```
- [ ] 定義 `STIFFNESS: Array[float]` = `[20.0, 20.0, 18.0, 14.0, 12.0, 14.0, 12.0, 10.0, 8.0, 10.0, 8.0]`
- [ ] 定義 `DAMPING_FACTOR: float = 0.25`
- [ ] 定義 `BONE_CONNECTIONS: Array` (索引對)：
  ```
  [HIPS, SPINE_TOP], [SPINE_TOP, HEAD_CENTER],
  [SPINE_TOP, L_ELBOW], [L_ELBOW, L_HAND],
  [SPINE_TOP, R_ELBOW], [R_ELBOW, R_HAND],
  [HIPS, L_KNEE], [L_KNEE, L_FOOT],
  [HIPS, R_KNEE], [R_KNEE, R_FOOT]
  ```

### B-2: `_ready()` 初始化
- [ ] 取得父節點 `character_body = get_parent() as CharacterBody2D`
- [ ] 用迴圈初始化 `positions[]` = `character_body.global_position + REST_OFFSETS[i]`
- [ ] 用迴圈初始化 `velocities[]` = `Vector2.ZERO`

### B-3: `_process(delta)` 彈簧更新
- [ ] 對每個質點 `i`：
  ```gdscript
  var target = character_body.global_position + REST_OFFSETS[i]
  var spring_force = (target - positions[i]) * STIFFNESS[i]
  velocities[i] += spring_force * delta
  velocities[i] *= pow(DAMPING_FACTOR, delta * 60.0)
  positions[i] += velocities[i] * delta
  ```
- [ ] 呼叫 `queue_redraw()` 觸發重繪

### B-4: `_draw()` 繪圖
- [ ] **頭部（空心正方形）**：
  ```gdscript
  var head_local = positions[HEAD_CENTER] - global_position
  draw_rect(Rect2(head_local - Vector2(5, 5), Vector2(10, 10)), Color.WHITE, false, 2.0)
  ```
- [ ] **骨幹連線**：遍歷 `BONE_CONNECTIONS`：
  ```gdscript
  var p1 = positions[conn[0]] - global_position
  var p2 = positions[conn[1]] - global_position
  draw_line(p1, p2, Color.WHITE, 2.0)
  ```

## 驗證（動態）
- IDE 無語法錯誤
- 執行後畫面出現：空心方形頭 + 身體 + T 字手臂 + 雙腿
