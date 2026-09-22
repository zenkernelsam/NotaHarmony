# ADR-0548: 形状识别仲裁双阈值覆盖（e5d.b 对齐）

## Status

Accepted, 2026-09-22.

## Context

`ShapeDetector.recognizeShape` 此前只做"三候选 argmax + `>0.2` 接受门"。
原版 `decompiled_1.0.3/sources/defpackage/e5d.java` 的 `b()` 在 argmax
之后、接受门之前还有两条覆盖规则：

1. 最佳候选为 POLYGON 且 `b16.h()`（最短边/最长边 < 0.25，边长严重不均）
   → 首个 `>0.3` 候选替代；再检查是否有 `>0.3` 的**正圆** ELLIPSE
   （`m06.h==m06.i`），有则再替代。
2. 最佳候选为 LINE → 首个 `>0.3` 的 ELLIPSE 替代。

即"弱胜者让位于像样的替代者"——手绘闭合曲线被误判为多边形/直线时
纠回椭圆/正圆。Harmony 缺这两条规则：一条歪歪扭扭的闭合涂鸦若恰好被
polygon 启发式以最高分胜出，会错误地多边形化而不是椭圆化。

## Decision

- `DetectionResult` 增加内部元数据 `kind/closed/circle/unevenEdges`；
  `circle` = 归一化后 `rx === ry`（对应 `m06.h == m06.i`）。
- 新增 `hasUnevenEdges(vertices, closed)`：闭合环计入 last→first 边，
  开放链只算相邻边（对应 `b16.g()` 的 `this.b` 回环追加）；判据
  `|minEdge|/|maxEdge| < 0.25`。
- `applyOriginalOverride` 按原版顺序执行两条覆盖；"首个候选"沿用
  Harmony 的评估序 line→ellipse→polygon。
- 新增常量 `ORIGINAL_SHAPE_OVERRIDE_CONFIDENCE = 0.3`、
  `ORIGINAL_POLYGON_UNEVEN_EDGE_RATIO = 0.25`；接受门 0.2 不变。

## Consequences

- 闭合团块（圈起来的涂鸦）在存在尚可的椭圆/正圆候选时正确纠回；
  纯直线 vs 椭圆的误判同理。
- 覆盖可能把原本胜出的 polygon 换成 ellipse——这正是原版行为。

## Alternatives Considered

- 不覆盖、仅 argmax：与原版不符（e5d.b 的覆盖分支是硬证据），拒绝。
- 用更平滑的启发式重加权：无原版依据，拒绝。

## Evidence

`docs/migration/evidence/original-shape-override-harmony-2026-09-22.md`
