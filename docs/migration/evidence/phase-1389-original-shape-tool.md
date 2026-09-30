# Phase 1389 证据 — 1.4.2 SHAPE 拖拽成形工具

> 源码证据：`decompiled_1.4.2`（1.4.2 APK，v1040002）。`1.0.3` 无 SHAPE 工具
> ——这是 1.4.2 全新引入的功能。

## 1. 工具枚举与默认工具箱种子

**`eti.java`** — 1.4.2 工具枚举在 1.0.3 基础上新增两个工具：

```
PEN(0) CALLIGRAPHY(1) PENCIL(2) HIGHLIGHTER(3) WHOLE_ERASER(4)
PARTIAL_ERASER(5) SELECTION(6) TEXT(7) LASER(8) … SHAPE(14)
```

- `SHAPE`（`eti.T`）为 ordinal 14 的新工具，**1.0.3 `a6f` 枚举无对应项**。

**`cc3.java H()` — Secondary 托盘默认种子**（全新装）：

```
O(0,POINTER) → P(1,LASER) → S(2) → Q(3,REVIEW) → R(4) → T(5,SHAPE)
SHAPE 行：zsi(i3,i2, eti.T, 5,
  g92(-16777216, 0)          // color = -16777216（黑），selectedColorWellIndex=0
  r2k(1, 2.0f)               // widthSize=2.0，selectedWidthSizeWellIndex=1
  o81Var, aj1Var, …, r5g.F)  // shapeKind = RECTANGLE
```

- SHAPE 在 Secondary 托盘 index **5**（`R`=index4 是 RULER，留空位）。
- SHAPE **有** color + width 状态（`g92`/`r2k` 非 null）——与 CALLIGRAPHY 不同，
  它有常规 brush 配置，故 `supportsBrushControls()`/`supportsColorControls()` 含之。
- `shapeKind` 默认 `r5g.F` = `RECTANGLE`。

## 2. ShapeKind 枚举（r5g.java）

```
RECTANGLE(0) ELLIPSE(1) DIAMOND(2) TRIANGLE(3) ARROW(4) LINE(5)
```

- `h5g.java:154-170` 形状选择器按 ordinal 取标签并渲染 24dp 形状图标 + 文字。
- `ca3.java:404` `ToolStateEntity.shapeKind` 列 = `TEXT DEFAULT 'RECTANGLE'`
  ——**存枚举名**（非 ordinal）；`fgf.java:46` 的迁移
  `ALTER TABLE ToolStateEntity ADD COLUMN shapeKind TEXT DEFAULT 'RECTANGLE'`。
- 同列族：`nibAngle REAL`、`nibFlatness REAL`、`stabilization INTEGER`（可空，
  仅 CALLIGRAPHY/SHAPE 用，其余 NULL）。

## 3. 拖拽→形状几何（u5g.java:117-186）

原版 `u5g` 是 SHAPE 工具的"拖拽成形渲染器"：`this.t`/`this.u` 为拖拽起点/终点，
包围盒 → 各 shapeKind 的形状路径：

| shapeKind | 拖拽映射 |
|-----------|---------|
| `LINE`(5)/`ARROW`(4) | 起点→终点线段；`ARROW` 端点 `arrowHead=SINGLE` |
| `RECTANGLE`(0) | 包围盒四角闭合多边形（isClosed） |
| `ELLIPSE`(1) | 包围盒内切椭圆（radiusX=w/2, radiusY=h/2） |
| `DIAMOND`(2) | 四边中点菱形（top中/右中/bottom中/左中） |
| `TRIANGLE`(3) | 顶点=上边中点 + 两底角 |

**约束修饰 `r().q`**（"绘制正形/45°"，触控笔按键/修饰触发）：
- 面积形状（RECT/ELLIPSE/DIAMOND/TRIANGLE）→ 包围盒取 `max(|dx|,|dy|)` 成正方形。
- `LINE`/`ARROW` → 拖拽方向吸附最近 45°（`round(atan2/π4)·π4`，保长度）。

**拖拽门限**：拖拽长度 ≤ `6.0`（画布单位）不产形。

## 4. CREATE_SHAPE 同步编码

`OriginalCreateShapePayloadEncoder` 校验：`originalTool`∈[0,7]、`originalStyle`∈[1,3]
（拒绝 variable-width 0）、`transform` 必须为恒等、polygon 闭合 ≥3 顶点、
line 箭头仅 NONE/SINGLE。SHAPE 工具产形以钢笔描边呈现 →
`originalTool=0(Pen)`、`originalStyle=1(MONO)`、拖拽无压感 `force=null`→落默认 1。

## 5. Harmony 移植落点

| 原版 | Harmony 文件 | 移植内容 |
|------|--------------|---------|
| `eti.T` + `r5g` | `core/model/BrushTypes.ets` | `ToolType.SHAPE=11`、`ShapeKind`(0..5)、`shapeKind`/`stabilization` 字段、`shapeKindToName/FromName` |
| `u5g` | `core/model/ShapeDragGeometry.ets` | `buildDragShape`：包围盒→6 类形状、约束修饰、6.0 门限 |
| `cc3.H()` | `EditorViewModel.createDefaultStates` | SHAPE 种子 secondary index5、RECTANGLE |
| `h5g` | `ui/editor/ShapeKindPicker.ets` | 6 类 swatch 选择页 |
| — | `NoteCanvasView` | `shapeDragActive`/`previewShape`/`commitShapeDrag` 拖拽-预览-提交 |
| `fgf.java:46` | `DatabaseHelper` migration 72 | `shape_kind`/`nib_*`/`stabilization` 列 |

## 6. 移植差异（显式记录）

- **约束触发源**：原版 `r().q` 由触控笔按键/修饰触发；Harmony 画布暂无
  stylus-button/修饰信号 → `buildDragShape` 的 `constrain` 参数已接好但当前
  默认 `false`（自由拖拽），待后续修饰源落地。
- **线样式**：原版 `ui_designsystem__line_style_{fixed,variable,dashed,dotted}`
  为 SHAPE 的逐形状线型选择器（虚线/点线描边渲染）——本阶段产形为 solid MONO，
  线型选择器留作后续 Phase。
- **MyScript**：1.4.2 引入 `HwrEngineService`（手写识别引擎）——后端/专有 SDK 域，
  fail-closed，不在本 Phase。
