# ADR-0819 — 子结构/值类/余枚举登记

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- 内联结构：ua0=64B SHA-512 资产哈希（8×Long）、qo5=8B
  op-id、cxc=12B 位置、utf=16B UUID、hu1=4B RGBA、qed/fqa=
  2×float、vy7=4×float、v01=13B+、ukb=2×long 录音段、bmb/hd1。
- Kotlin 值类：tmf/xgb=long、mmf=int、cmf=byte、ymf——
  全部 Comparable；imf 普通类。
- 余枚举：ww9={STRING,BOOLEAN}（PDF 字段值）、u76={POINTER,
  PEN,HIGHLIGHTER,ERASER}（对端指针）。
- 小表：z1d/lxc/m2d/akb 单字段；dp5/qqe 两字段。

## Harmony 决策

- `NoteExporter` 的 `assets/<sha512>` 键与 ua0 64B 哈希对应。
- op-id/位置经 OperationIdentity/SeqId 层；值类语义由持久
  列承载；新枚举登记备查。

## Parity 状态

等价/已登记——线层类型清单闭环。

## 验证

- `d02-substruct-valueclass-registry.mjs`：23/23 通过。
- 全量 Replay 与双 HAP 构建见 Phase 875 提交。
