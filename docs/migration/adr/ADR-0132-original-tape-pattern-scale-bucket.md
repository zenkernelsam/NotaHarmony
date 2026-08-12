# ADR-0132：按原版 scale bucket 缓存并生成 Tape pattern

## 状态

Accepted - Phase 155（2026-08-12）

## 背景

原版 1.0.3 `qfe.a()` 使用 `round(clamp(tapeWidth, 1..8) * 2)` 生成 pattern cell 的
`scaleBucket`，并将 `pattern、overlayColor、FLOWERS 时的 tapeColor、scaleBucket`
组成 `mfe.PatternCellKey`。bitmap 的像素尺寸和 shader 的逻辑重复周期都会随 bucket 变化。

Harmony 旧实现只有固定密度 tile，所有 Tape 宽度复用同一逻辑周期，宽 Tape 因而显得过密，
同时缓存身份没有包含宽度。

## 决策

- 在 `getTapePatternTile()` 中按原版 clamp 和 round 规则计算 2..16 的 bucket。
- 将 bucket 纳入 tile key；FLOWERS 继续纳入 tapeColor，其余图案不扩大颜色维度。
- 以 `bucket / 2` 放大 tile 的逻辑宽高和像素尺寸，绘制坐标保持原版基准图案。
- 非有限宽度回退到原版可接受范围的下界，避免 NaN/Infinity 污染 key 或尺寸。

## 后果

不同 Tape 宽度拥有独立且可淘汰的 bitmap，pattern 周期与原版一致；缓存最多仍为 32 项。
真机像素密度和 Canvas shader 的最终观感仍需设备验收。
