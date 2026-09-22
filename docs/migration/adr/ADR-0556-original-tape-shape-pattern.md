# ADR-0556: Tape 形状元素的图案层渲染

## Status

Accepted, 2026-09-28.

## Context

原版胶带元素是 `ShapeImpl` + `tapePatternRegister` 实体（`dm2` 校验
tapePattern 仅属 TAPE 工具），渲染为笔带主体 + `ife` 图案层（与 Ink
胶带共用 `qfe` 瓦片管线）。Harmony 将导入的胶带物化为
`ShapeElement`（`originalTool === 3` + `originalTapePattern`），但
`ShapeCanvasRenderer` 只画纯色笔带——图案层缺失；Phase 586 的点按
揭示/全局开关对形状已收 ID 却无视觉效果。

## Decision

- `ShapeCanvasRenderer.renderTapePatternOverlay`：`originalTool === 3`
  时在 `strokeShape` 笔带之后逐 `ShapeStrokeComponent` 合成等价
  `StrokeElementData`（与 `OriginalShapePartialEraser:631` 残余转换
  同一语义：`tapePattern = originalTapePattern ?? STRIPES`），经共享
  `renderer.renderTapePattern` 填充 `WidthOutlineBuilder` 外轮廓。
- 揭示门控：renderer 新增 `revealedTapeIds: Set<string>`；
  `NoteCanvasView.aboutToAppear` 共享同一 `Set` 实例（与
  `strokePainter` 一致）；命中即跳过图案层——`ife=null` 等价。
- `renderShape` 增 `viewportZoom`（默认 1）；两个调用点传
  `this.viewport.zoom`，与 `originalTapePatternScaleBucket` 对齐。

## Consequences

- 导入 `.note` 的胶带元素恢复原版图案视觉；PLAIN/缺失 pattern 行为与
  原版一致（纯色带 / STRIPES 兜底）。
- 点按揭示与全局 Hide/Reveal 对 tape 形状立即获得视觉效果（Phase 583/586
  已收其 ID）。
- 偏差记录：原版 ShapeImpl 的填充/边框另有参数面；本阶段仅补图案层，
  填充（`fillColor`）仍走既有 `fillShape` 路径。
- 回放 `d02-original-tape-shape-pattern.mjs` 钉死门控、合成字段、
  调用顺序与 zoom 接线。
