# ADR-0880 — 锚类型字段布局

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `hd1`=CanvasAnchor 20B inline{page:cxc@0,
  origin:fqa@12}。
- `lhe`=TextAnchor 表{textField:qo5@c(4),
  selection:qqe@c(6)}。
- `my3`=EntityAnchor 表{entities:qo5[]@c(4)}。
- `cwb`=ReplyAnchor 8B inline{root:qo5}。

## Harmony 决策

锚类型布局对齐。

## Parity 状态

等价。

## 验证

- `d02-anchor-layouts.mjs`：10/10 通过。
- 全量 Replay 809 文件绿，见 Phase 936 提交。
