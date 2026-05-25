# Module C: 實證單元測試

## 目標
完全改寫舊測試，確保每一個斷言都有真實的「物理位移差值」作為依據，杜絕假性通過。

## 原子任務清單

### C-1: 更新 `tests/test_movement.gd`
- [ ] `extends "res://addons/gut/test.gd"` (路徑繼承，不得用全域類)
- [ ] **Setup**: `var player = preload("res://Player.tscn").instantiate()` → `add_child_autofree(player)`
- [ ] **取得 Drawer 引用**: `var drawer = player.get_node("ProceduralDrawer")`
- [ ] **觸發 WASD 綁定**：呼叫 `player._ready()` 確保 InputMap 被初始化
- [ ] **記錄初始位置**: `var init_x = player.position.x`
- [ ] **送出 KEY_A 事件**:
  ```gdscript
  var key_a = InputEventKey.new()
  key_a.keycode = KEY_A
  key_a.pressed = true
  Input.parse_input_event(key_a)
  ```
- [ ] **跑 60 幀**（同時驅動物理與彈簧）:
  ```gdscript
  for i in range(60):
      player._physics_process(1.0 / 60.0)
      drawer._process(1.0 / 60.0)
  ```
- [ ] **斷言 A**: `assert_true(player.position.x < init_x - 40.0, "角色本體必須至少向左移動 40px")`
- [ ] **斷言 B（彈簧滯後實證）**: 計算 HIPS 質點與靜止目標的偏移：
  ```gdscript
  var hips_rest_x = player.global_position.x + 0.0  # HIPS rest offset x = 0
  var hips_actual_x = drawer.positions[0].x          # index 0 = HIPS
  assert_true(abs(hips_actual_x - hips_rest_x) > 0.5, "HIPS 質點必須因慣性滯後，證明彈簧物理有效")
  ```

### C-2: 建立 `tests/test_spring_physics.gd`（取代舊的 `test_skeleton.gd`）
- [ ] `extends "res://addons/gut/test.gd"`
- [ ] **高速移動後急煞測試**:
  - Setup: 實體化 player，取得 drawer
  - 送出 KEY_A，跑 60 幀（高速移動）
  - 瞬間煞車：`player.velocity.x = 0`，送出 KEY_A released
  - 再跑 3 幀 `drawer._process(1.0/60.0)`（不跑 physics，只跑彈簧）
  - **斷言**：
    ```gdscript
    var HEAD = 2  # HEAD_CENTER index
    var head_rest_x = player.global_position.x + 0.0  # HEAD rest offset x = 0
    var head_actual_x = drawer.positions[HEAD].x
    assert_true(abs(head_actual_x - head_rest_x) > 1.0,
        "急煞後頭部質點必須因慣性偏移超過 1px（Q彈物理實證）")
    ```

### C-3: 確保舊的 `test_skeleton.gd` 被移除或清空
- [ ] 刪除或清空 `tests/test_skeleton.gd`（其骨骼測試邏輯已被取代）
- [ ] 加入 `# DEPRECATED: replaced by test_spring_physics.gd` 標頭
