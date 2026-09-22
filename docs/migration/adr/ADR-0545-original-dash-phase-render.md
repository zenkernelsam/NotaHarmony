# ADR-0545: DASH/DOTS 虚线相位恒为 0，`backingDashPhase` 不进入渲染

## Status

Accepted, 2026-09-22.

## Context

审计缺口清单 1.1 将 `Canvas2DStrokeRenderer.ets` 列为未审文件，并挂起两条
线索：高亮混合模式疑似近似、虚线/点参数未与原版比对。本 Phase 完成该文件
对 `c5g`/`e16`/`p16`/`yyd`/`ft1`/`o8j`/`uyd`/`rz1`/`l06`/`zx1`/`n8j`
的对照。

比对发现 Harmony 自 ADR-0012 起把 `styleMap[0].backingDashPhase` 当作
`lineDashOffset` 应用到 DASH/DOTS 中心线——ADR-0012 当时明确把「dash
phase 正负方向未验证」列为开放项。

## Evidence

- 原版两处 Java 虚线渲染（`c5g.java:223/237`、`e16.java:131/147`）均用
  `new DashPathEffect(intervals, 0.0f)`，相位为字面量 0。
- `backingDashPhase` 全部读取点（`s06:397`、`qee:84`、`o0j:566` 等）只流入
  `rz1.H` → `l06.phaseOffsetPx`（RAINBOW/GLITTER 特效相位，ADR-0046）。
- 切片推进 `ft1.java:91` 仅更新 StyleMap 持久字段，服务于特效相位连续性，
  与渲染相位无关。
- `backingDashPeriod` 无任何渲染消费方。

## Decision

- `renderCenterPath` 移除 `setLineDashOffset` 应用；DASH/DOTS 虚线相位恒为
  0，与原版两处渲染器一致。
- StyleMap 的 `backingDashPhase`/`backingDashPeriod` 继续无损解码、持久化、
  切片推进与特效物化——仅渲染消费方被移除。
- 高亮 alpha 覆盖 107 + SRC_OVER 核对为**精确对齐**而非近似，澄清审计疑点。

## Consequences

- 对 backingDashPhase ≠ 0 的切片/导入笔画，Harmony 渲染结果与原版一致
  （图案不再沿路径偏移）；新建笔画（phase=0）无可见变化。
- 原生特效层（WetMirror/androidx.ink）若另有相位消费，属 ADR-0046 已声明
  的 fail-closed 范围，不影响本决策。
