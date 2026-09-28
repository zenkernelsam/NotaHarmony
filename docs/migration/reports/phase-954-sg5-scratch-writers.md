# Phase 954 报告 — `sg5` 草稿池写侧

## 范围

sg5.java 写侧方法 + exc.java + wj9/o1 提供器。纯审计。

## 原版发现

- 13 持有者全实名（fl6[] 属性委托表）：3 通用 +
  Id/SeqId/StyleMap/RecordingSegment/Point/Size/
  ModifyPosition/DuplicateOp/OpAck/Op。
- `f` = cxc 12B 规范写器（与 nti.X 字节一致）。
- `g` = 元素提供器工厂（空→d1.W；list→o1；table→wj9 配对）。
- `exc` = SeqId Comparable，全序 ts→site→index。

## 产出

- 证据：`phase-954-sg5-scratch-writers.md`
- Fixture：`d02-sg5-scratch-writers.mjs`（22/22）
- ADR-0898；全量 Replay 827 文件绿。
