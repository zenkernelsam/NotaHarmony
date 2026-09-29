# ADR-0991 — 墨迹操作载荷与 u16 工具枚举

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `dm2` CreateInk 20 字段：三段编码路径、工具/样式/
  颜色/宽度/nib 参数/audioDuration/inkEffects。
- `gd` AddPathElements 逐点 `ddg.b(po4)` 校验。
- `wd8` ModifyInk 19 字段（inks 列表替代单 ink，无
  audioDuration），inks>0 + 禁置空 centerPath。
- `u16` 工具枚举 8 值 byte 码；`po4` 触控笔点实体。

## Harmony 决策

20/19 字段语义与三段路径编码保留；u16 wire 对齐；
笔点校验逐条保留。

## Parity 状态

等价。

## 验证

- `d02-ink-ops.mjs`：12/12 通过。
