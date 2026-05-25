# Module 3: 角色骨骼與物理搭建 (Skeleton & Jiggle Setup)

- [x] 建立 `Player.tscn`，根節點設為 `CharacterBody2D`。
- [x] 加入 `CollisionShape2D` (CapsuleShape2D)。
- [x] 加入 `Skeleton2D`，並建立對應的 `Bone2D`：
  - [x] `Hips`
  - [x] `Spine` -> `Head`
  - [x] `LeftUpperArm` -> `LeftLowerArm`
  - [x] `RightUpperArm` -> `RightLowerArm`
  - [x] `LeftUpperLeg` -> `LeftLowerLeg`
  - [x] `RightUpperLeg` -> `RightLowerLeg`
- [x] 加入 `SkeletonModificationStack2D`。
- [x] 針對脊椎與四肢分別加上 `SkeletonModification2DJiggle`。
- [x] 微調 Stiffness 與 Damping 以確保 Q彈搖擺效果。
