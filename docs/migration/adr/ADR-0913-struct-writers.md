# ADR-0913 — 内联结构写器字节序终证

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

FlatBuffers 自底向上构造 → 写器逆序推字段：

- `wtf.b` utf：t(8,16)+x(low)+x(high) →
  `{bitsHigh@0,bitsLow@8}`。
- `rz1.b0` v01：t(4,16)+s(3)+u(y01)+嵌套 cxc
  t(4,12){idx,ts,pad2,site} → `{cxc@0,y01@12}`。
- `apb.Z` qed：t(4,8)+两 float → `{width@0,height@4}`。
- `y5j.c` hd1：t(4,20)+嵌套 fqa@+12 + cxc@+0 →
  `{page:cxc@0,origin:fqa@12}`。
- `efj.b` cwb：嵌套 qo5 `{site@0,ts@4}`。

写↔读字节对称全部实证——写侧取证链闭合。

## Harmony 决策

Harmony encode* 已逐字节对齐（既有 Replay）；无需变更。

## Parity 状态

等价。

## 验证

- `d02-struct-writers.mjs`：13/13 通过。
