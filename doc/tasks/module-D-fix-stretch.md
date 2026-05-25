# Module D: 階層式彈簧與不脫離四肢

## 目標
徹底解決四肢斷開與拉伸的問題，引入父子階層追蹤，以及強化重力與彈簧係數，實現真正的火柴人 Q 彈感。

## 內容
- 修改 `procedural_drawer.gd`
- 新增 `PARENTS` 陣列定義父子關係
- 彈簧目標座標改為 `target = positions[parent] + local_offset`
- 繪圖時直接連線 `p1` (parent) 和 `p2` (child)
- 調整 `STIFFNESS=250`, `DAMPING=12`, `GRAVITY=400`
