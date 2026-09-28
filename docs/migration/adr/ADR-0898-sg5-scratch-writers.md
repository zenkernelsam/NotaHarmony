# ADR-0898 — `sg5` 草稿池写侧 + `exc` SeqId 排序

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `sg5` = 13 属性委托 + cz8 池（容量 26）+ ThreadLocal；
  持有者实名：offsets/nestedOffsets/usingOffsets +
  Id/SeqId/StyleMap/RecordingSegment/Point/Size/
  ModifyPosition/DuplicateOp/OpAck/Op。
- `sg5.f(a,exc)` = **cxc 12B 规范写器**（逆序 idx→ts→pad→site），
  与 `nti.X` 逐字节一致；所有 `cxc[]` 向量元素共用。
- `sg5.g(list)` = 元素提供器工厂：空→`d1.W` 哨兵，否则 `o1`；
  与 `wj9`（表型）配对分流工厂/写器路径。
- `exc` = SeqId Comparable iface，**A0 全序 = timestamp→site→index**。

## Harmony 决策

写侧逆序布局等价（Replay 覆盖）；`exc.A0` 位置全序语义
（Lamport ts 优先）需在 Harmony 文本位置比较中镜像。

## Parity 状态

等价（排序语义已断言）。

## 验证

- `d02-sg5-scratch-writers.mjs`：22/22 通过。
- 全量 Replay 827 文件绿，见 Phase 954 提交。
