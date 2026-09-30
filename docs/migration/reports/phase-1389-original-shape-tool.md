# Phase 1389 — 1.4.2 SHAPE 拖拽成形工具移植

## 目标

落地 1.4.2 新增的 SHAPE 工具（`eti.T`，ordinal 14）。与 CALLIGRAPHY（笔画管线）
不同，SHAPE 是**拖拽-预览-提交**的成形工具：按下锚定包围盒一角、拖动实时成形、
松手提交 ShapeElement。1.0.3 无此工具——纯 1.4.2 新功能。

## 原版证据

- `eti.java`：SHAPE(14) 独立工具。
- `r5g.java`：6 类 `RECTANGLE/ELLIPSE/DIAMOND/TRIANGLE/ARROW/LINE`（ordinal 0..5）。
- `cc3.java H()`：全新装默认 SHAPE @ Secondary index5（RULER=4 留空），
  color=-16777216、width=2.0、shapeKind=RECTANGLE。
- `h5g.java:154-170`：形状选择器按 ordinal 取标签 + 图标 + 选中态。
- `u5g.java:117-186`：拖拽→形状几何（包围盒映射 + 约束修饰 + 6.0 门限）。
- `ca3.java:404`/`fgf.java:46`：`shapeKind TEXT DEFAULT 'RECTANGLE'`（枚举名存储）。
- `ui_tools__shape`="Shape"；`ui_designsystem__shape_tool_*` 4 层图标。

## 实现

| 层 | 变更 |
|----|------|
| 枚举 | `ToolType.SHAPE = 11`；`ShapeKind`(0..5)；`shapeKind`/`stabilization` 字段 |
| 编解码 | `shapeKindToName/FromName`（枚举名↔ordinal，`shape_kind` TEXT 列） |
| 几何 | `ShapeDragGeometry.buildDragShape`：u5g 包围盒→6 类形状、约束、6.0 门限 |
| 手势 | `NoteCanvasView` shapeDragActive/shapeDragStart/previewShape/commitShapeDrag |
| 渲染 | `renderFrame` 强制 orderedRender + 渲染 previewShape |
| 同步 | 提交携 `originalCreate` 预留身份（encodeOperationId），persist 发 CREATE_SHAPE |
| 默认 | `createDefaultStates` 插 SHAPE@Secondary index5，RECTANGLE |
| 持久化 | DB v71→72：`shape_kind`/`nib_angle`/`nib_flatness`/`stabilization` 列 |
| UI | `shape` 4 层 glyph、`toolGlyphKey`/`COLOR_GLYPHS`/`toolTypeLabel`、6 类 `ShapeKindPicker` |

## 手势语义（u5g 对齐）

- **按下**：锚定 `shapeDragStart`，不进 StrokeSession。
- **拖动**：`previewShape = buildDragShape(kind, start, cur, color, width)` 实时成形。
- **松手**：`commitShapeDrag` 提交（点按未成形 → 丢弃）；携 CRDT 身份同步。
- **取消**：`cancelActiveInteraction` 清 shapeDragActive/previewShape。
- **约束**（原版 `r().q`）：面积形状取正方形、线/箭头 45° 吸附——`constrain`
  参数已接好，待 stylus-button 修饰源落地后开启。

## 边界 / 后续

- 线型选择器（`line_style_fixed/variable/dashed/dotted`）未移植——产形为 solid MONO。
- 修饰约束触发源（触控笔按键）未在 Harmony 画布暴露——`constrain` 预留。
- MyScript `HwrEngineService` 手写识别为专有 SDK 域 → fail-closed。

## 验证

- Replay fixture `d02-original-shape-tool.mjs`：68 项绿。
- 全量 Desktop Replay 基线：见提交说明。
- note@ohosTest / note@default：clean 构建成功。

## 产出

- 证据 `phase-1389-original-shape-tool.md`；ADR `ADR-1325`；
  Replay `d02-original-shape-tool.mjs`。
