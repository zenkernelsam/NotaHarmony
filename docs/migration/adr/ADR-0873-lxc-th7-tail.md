# ADR-0873 — `lxc` SeqMove + `th7` 列表 + 尾类分流

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `lxc` = SeqMove{toId:cxc@0}——移动以目标位置 ID
  表达（CRDT 序内锚定）。
- `th7` = `u4` 可变 Object[] List——lv2 物化器
  builder/结果两相类型（m18.S/E 对）。
- `ume` = Android BottomSheet UI 类（非线型）；
  `m15`/`o15` = 序列化上下文族（非载荷）。

## Harmony 决策

SeqMove 单字段编码对齐；非线型类不移植。

## Parity 状态

等价（线层引用图无遗漏）。

## 验证

- `d02-lxc-th7-tail.mjs`：7/7 通过。
- 全量 Replay 802 文件绿，见 Phase 929 提交。
