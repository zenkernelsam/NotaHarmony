# ADR-0823 — 余子表实名登记（akb/dp5/qqe/z1d/m2d/lxc）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `akb` = `RecordingAsset{metadata: wa0}`。
- `dp5` = `ImageAsset{metadata: wa0, size: qed}`。
- `qqe` = `TextSelection{anchor: cxc, focus: cxc}`。
- `z1d` = `SetBool{value: Boolean}`（`me8` 布尔 setter）。
- `m2d` = `SetPageBackground{value: nz9}`（ge8/td8/l2d 用）。
- `lxc` = `SeqMove{toId: cxc}`（ge8 moveTo 目标；
  `u5j.s`：页索引→`bfj.b` cxc→`egh.a` lxc）。
- setter 包装族闭合：`?2d` 单字段 + z1d/m2d/lxc 语义命名。
- `akb`/`dp5` 复用 `wa0` 作资产元数据——资产引用模型统一。

## Harmony 决策

- ModifyPage moveTo/backgroundWinner ↔ SeqMove/
  SetPageBackground；RecordingAsset wa0 ↔ 录音资产登记；
  ImageAsset metadata+size ↔ ImageBlock 几何/asset 键；
  z1d ↔ 布尔 setter 槽。

## Parity 状态

等价（字段语义 1:1 实名对齐）。

## 验证

- `d02-subtable-registry.mjs`：23/23 通过。
- 全量 Replay 与双 HAP 构建见 Phase 879 提交。
