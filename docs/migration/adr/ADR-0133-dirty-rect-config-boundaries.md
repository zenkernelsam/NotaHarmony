# ADR-0133：DirtyRectTracker 配置边界

## 状态

Accepted - Phase 156（2026-08-12）

## 背景

`DirtyRectTracker` 的正常语义是页面坐标脏区、按 zoom 换算 padding，并在超过区域上限时
退化为联合矩形。旧构造函数仅使用 `Math.max`；当调用方传入 `NaN` 或无穷值时，字段仍为
非有限数，导致 padding 生成 NaN，或 `remaining.length > maxRegions` 永远失效。

## 决策

- 有限 `screenPadding` 仍按 `max(0, value)` 处理；非有限值回退默认 3。
- 有限 `maxRegions` 向下取整并至少为 1；非有限值回退默认 8。
- `markDirty()` 原有非法/非正 zoom 回退 1 的行为保持不变。

## 后果

异常配置不会污染脏区几何或区域上限；正常调用的结果不变。未对 bounds 本身做猜测性修复，
调用方仍需提供页面坐标矩形。
