# 证据：原版 Tape 形状元素的图案层（2026-09-28，Phase 587）

证据源：`decompiled_1.0.3/sources/defpackage/*.java`（1.0.3 反编译）+ 本仓库
已解码链路。

## 1. 原版：胶带是 ShapeImpl 实体

- `dm2` 校验：`tapePattern` 仅在 tool=TAPE 时存在（Phase 582/585 已引证）。
- 胶带元素以 `ShapeImpl` + `tapePatternRegister` 入库（`OriginalShapeGroup`
  op 字段 8/9 → `originalTapePattern`，本仓解码见
  `note/src/main/ets/data/OriginalShapeGroupOperation.ets:186,260`）。
- 渲染侧（`e16`/`d5g` bake 路径）：笔带主体 + `ife` 图案填充在笔画外
  轮廓上——与 Ink 胶带共用 `qfe` 瓦片管线（`ife` 图案注册表；
  `ife=null` 即"已揭示"视觉）。

## 2. Harmony 缺口（Phase 587 修复）

导入的胶带元素在本仓物化为 `ShapeElement`（`originalTool === 3` +
`originalTapePattern`，`ElementTypes.ets:44-51`），但
`ShapeCanvasRenderer.strokeShape` 只画纯色笔带——**无图案层**。
旁证：局部橡皮残余路径 `OriginalShapePartialEraser:631` 早已把
`originalTool===3` 形状合成带 `tapePattern` 的 `StrokeElementData`，
说明转换语义早已确立，缺的是整体形状的等价渲染。

## 3. Harmony 对齐（Phase 587）

| 原版 | Harmony |
| --- | --- |
| ShapeImpl(tapePatternRegister) → 笔带 + ife 图案 | `ShapeCanvasRenderer.renderTapePatternOverlay`：`originalTool === 3` 时在 `strokeShape` 笔带之后，逐 `ShapeStrokeComponent` 合成等价 `StrokeElementData`（`tapePattern = originalTapePattern ?? STRIPES`，`brushWidth = shape.strokeWidth`，`color = shape.color`）走既有 `renderer.renderTapePattern`（`qfe` 瓦片 + `WidthOutlineBuilder` 外轮廓） |
| `ife=null` = 已揭示视觉 | `revealedTapeIds.has(shape.id)` 时跳过图案层；`NoteCanvasView` 把同一 `Set` 引用共享给 `shapeRenderer`（与 `strokePainter` 同一实例，`yd9.j` 会话级语义一致） |
| PLAIN 图案 = 纯色带 | `pattern === TapePattern.PLAIN` 直接跳过 |
| 图案随视口缩放取桶 | `renderShape` 新增 `viewportZoom` 参数，两个调用点传 `this.viewport.zoom`（与 `renderTapePattern` 的 `originalTapePatternScaleBucket` 一致） |

## 4. Replay

`docs/migration/replays/d02-original-tape-shape-pattern.mjs`（15 项断言）。
