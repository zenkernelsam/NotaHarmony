# Phase 936 报告 — 四锚类型字段级布局

## 范围

hd1/lhe/my3/cwb 访问器→偏移钉死。纯审计。

## 原版发现

- hd1=CanvasAnchor 20B inline{page:cxc@0,
  origin:fqa@12}。
- lhe=TextAnchor{textField:qo5@c(4),
  selection:qqe@c(6)}。
- my3=EntityAnchor{entities:qo5[]@c(4)}。
- cwb=ReplyAnchor 8B inline{root:qo5}。

## 产出

- 证据：`phase-936-anchor-layouts.md`
- Fixture：`d02-anchor-layouts.mjs`（10/10）
- ADR-0880；全量 Replay 809 文件绿。
