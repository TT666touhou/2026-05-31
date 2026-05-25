# Module A: Player.tscn 場景清理

## 目標
將 `Player.tscn` 的骨骼相關節點全數移除，精簡為最小可用結構。

## 原子任務清單
- [ ] 刪除所有 `[sub_resource type="SkeletonModification2DJiggle" ...]` 區塊（共 5 個）
- [ ] 刪除 `[sub_resource type="SkeletonModificationStack2D" ...]` 區塊（共 1 個）
- [ ] 刪除 `[node name="Skeleton" type="Skeleton2D" ...]` 及其所有子節點（Bone2D × 11 個）
- [ ] 確保 `[gd_scene]` 標頭**不含** `load_steps=X`（防止 File Corrupt）
- [ ] 確保 `[ext_resource]` 全在最頂端（防止 Parse Error）
- [ ] 確認最終結構只剩：`Player(CharacterBody2D)` → `CollisionShape2D` + `ProceduralDrawer(Node2D)`

## 驗證（靜態）
- IDE 不報任何 `.tscn` 解析錯誤
- `Player.tscn` 可在 Godot 中開啟不崩潰
