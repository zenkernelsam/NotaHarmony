# ADR-1173：ev9 相机运动传感器（视差）

## 状态

已接受（Phase 1229）。

## 决策

`ev9` TYPE_ROTATION_VECTOR → 相对旋转矩阵 →
`dv9` 监听 → `bpd` 笔记视差 → Harmony `sensor` 框架
`ROTATION_VECTOR` + XComponent 视差回调。

## 理由

`ev9` getRotationMatrixFromVector + 屏幕旋转重映射 +
首帧基线 `c` + `a=current×baseline` 相对矩阵 +
`f[i].a(roll,matrix)` → `bpd` —— 相机视差（设备倾斜
→ 内容偏移）。

## 后果

Harmony 视差 = ROTATION_VECTOR sensor + 相对矩阵 +
XComponent transform —— 视差语义保真。
