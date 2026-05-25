# Module G: 相位驅動 IK 行走 (Phase-Driven IK Locomotion)

## 目標
透過距離匹配相位器 (Distance-Matching Phase) 取代原本基於時間與距離差的碎步機制，徹底解決「倒退走」、「滑步」與「沒有完整跨步交叉」的問題。

## 內容
- 修改 `procedural_drawer.gd` 內的步態生成邏輯。
- 引入基於絕對世界座標 $X$ 的 `global_phase`。
- 實作分段式腳步偏移函數 (支撐期 vs 擺盪期)。
- 保留原本的視覺防拉伸與雙膝 IK 計算。

## 狀態
- [ ] 實作 Phase-Driven 腳步計算
- [ ] 調整骨盆與身體的隨動起伏 (Bobbing)
- [ ] 驗證實體防滑步效果
