# Phase 1229 报告 — ev9 相机运动传感器

## 完成内容

- `ev9`=SensorEventListener（TYPE_ROTATION_VECTOR）；
- 屏幕旋转重映射 + 首帧基线 + 相对旋转矩阵
  （`a=current×baseline`）+ `f[i].a(roll,matrix)` →
  `bpd` 笔记内容视差（设备倾斜 → 内容偏移）。

## 产出

- evidence `phase-1229-ev9-camera-motion.md`
- fixture `d02-ev9-camera-motion.mjs`（10/10）
- ADR-1173
