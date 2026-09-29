# Phase 1047 报告 — 墨迹操作载荷

## 范围

`dm2`/`gd`/`wd8` 墨迹操作、`u16` 工具枚举、`po4` 笔点。
纯审计。

## 原版发现

- CreateInk 20 字段：page/origin/rotation/scale/tool/style/
  tapePattern/color/width + center/custom/fill 三段编码路径
  + fillColor/styleMap/zIndex/audioDuration/nibAngle/
  nibFlatness/inkEffects/inkEffectsTinted。
- AddPathElements 逐点校验（`di7` 向量迭代 `ddg.b`）。
- ModifyInk 19 字段：inks 列表+同上字段（无 audioDuration），
  inks>0、禁置空 centerPath。
- `u16` = 8 工具枚举（PEN..LASER，byte 0-7）；
  tapePattern 仅 TAPE 合法。
- `po4` = 笔点实体（azimuth/altitude/width/force+位置，
  `s8a` 哨兵）。

## Harmony 决策

字段语义/校验/文案逐条保留；u16 wire 对齐。

## 产出

- 证据：`phase-1047-ink-ops.md`
- Fixture：`d02-ink-ops.mjs`（12/12）
- ADR-0991；全量 Replay 见本提交。
