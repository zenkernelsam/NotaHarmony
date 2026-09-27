# ADR-0867 — 剩余子结构四枚

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `ukb` = RecordingSegment{startTime:long@0,
  endTime:long@8} 16B 内联结构。
- `bmb` = Rect{origin:fqa, size:qed} 16B。
- `qqe` = TextSelection{anchor:v01, focus:v01} 表。
- `yyd` = StyleMap{seed:int@0, refPoint:fqa@4,
  dashPhase:float@12, dashPeriod:float@16} 20B——
  墨迹虚线渲染参数。
- 内联结构宽度谱系实证：qo5 8B / cxc 12B /
  ukb 16B / bmb 16B / yyd 20B / ua0 64B。

## Harmony 决策

结构宽度与字段偏移对齐；样式贴图虚线参数模型化。

## Parity 状态

等价（op 载荷全引用图闭合）。

## 验证

- `d02-sub-structs.mjs`：12/12 通过。
- 全量 Replay 796 文件绿，见 Phase 923 提交。
