# Phase 1056 报告 — 值类型清单

## 范围

`fqa`/`qed`/`bmb`/`vy7`/`hu1`/`k3a`/`tmf`。纯审计。

## 原版发现

- Point{x,y}、Size{width,height}（访问器 d=width,
  c=height 序反）、Rect{origin,size}、Margins{top,bottom,
  left,right}（非负校验）。
- Color{bitsR/G/B/A} byte×4（cmf.a 格式化）。
- Paper{flair,flairSpacing,flairBleeds,flairCentered,
  backgroundColor,legacyPaperIndex}——alpha==1 强制。
- `tmf` Comparable long（serverTime/audioTime/zIndex 通用）。

## Harmony 决策

布局/校验/序数包装保留。

## 产出

- 证据：`phase-1056-value-types.md`
- Fixture：`d02-value-types.mjs`（12/12）
- ADR-1000；全量 Replay 见本提交。
