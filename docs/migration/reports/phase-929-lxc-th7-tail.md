# Phase 929 报告 — lxc/th7 + 尾类分流

## 范围

SeqMove 布局 + 列表实现类 + 非线型分流。纯审计。

## 原版发现

- lxc=SeqMove{toId:cxc} 单字段——CRDT 序内锚定移动。
- th7=u4 可变 List（Object[] 支撑）= lv2 物化器
  builder/结果两相。
- ume=Android UI 类、m15/o15=序列化上下文——非线型。

## Harmony 核对

编码对齐；非线型不移植。

## 产出

- 证据：`phase-929-lxc-th7-tail.md`
- Fixture：`d02-lxc-th7-tail.mjs`（7/7）
- ADR-0873；全量 Replay 802 文件绿。
