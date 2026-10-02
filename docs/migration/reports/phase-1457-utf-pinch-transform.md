# Phase 1457 修复报告 — utf 双指捏合选区变换会话

## 目标

补齐原版 1.4.2 变换会话族最后一员 `utf`（PinchTransform）：
双指捏合作用于**选区内容**的等比缩放+吸附旋转，此前 Harmony
双指只有视口 zoom/pan，第二指落下即取消交互。

## 原版证据（decompiled_1.4.2）

- `utf.java`：PinchTransform 会话类——scale=1.0/rotation=0.0 起，
  枢轴 = 第二指触点（构造器 c=d=f=j），携 initialSelectionState。
- `guf.y`：建立门——h==null、选区有效、非 hsf/isf.h/全锁定，
  第二指经选区旋转反旋后落界内才成立。
- `guf.v`：更新——距离比等比缩放、连线角增量 `twm.d` 吸附
  （90° 倍数 ±5°），枢轴逐帧更新；结束 `a.c` 提交保选区。
- `guf.m`：`T(p)·R·S·T(−p)·base` 复合应用，`z` 页框钳制。

## Harmony 实现（NoteCanvasView.ets）

- 新增 `pinchSelectSession` 等 6 个会话字段。
- `tryStartSelectionPinch`：多点按下分支内、取消交互之前；
  门 = 无活动变换会话 + 非点除 + 非全锁定 + 非进行中选区 +
  `pointInSelectionRect` 界内第二指；捕获基变换与 undo 快照。
- `applySelectionPinch`：距离比等比缩放 + `snapSelectionRotateDelta`
  （twm.d 等价：π/2 步进、5° 阈值）+ 双指中点枢轴，
  经 `resizeSelected(s, θ, p, p, base)` 重建变换。
- `endSelectionPinchCommit`：单次 TRANSFORM_ELEMENTS 撤销 +
  persist + 重选 id 保选区。
- 取消路径恢复 `dragBefore*`；视口 Pinch/Pan 手势回调按
  `pinchSelectSession` 门控。

## 差异登记

- 界内判定走 `pointInSelectionRect`（旋转判定等价，路径不同）。
- `lsf.c` showUncroppedImage 门未移植（无对应状态）。
- `guf.m z=true` 页框钳制未实现（提交不拉回页内）。

## 验证

- 新 fixture `d02-original-pinch-session-utf.mjs`：22 项绿。
- 全量基线、note@default、note@ohosTest 见提交说明。
