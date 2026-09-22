# 原版吸附对齐（snap-to-grid / alignment guides）— Harmony 证据文档

- 日期：2026-09-22
- Phase：568
- 结论：已对齐（移动拖拽路径全量移植；形状顶点/控制点拖拽路径 fail-closed 登记差异）

## 原版证据（decompiled_1.0.3）

### 特性开关

- `ac4.S` = `SNAP_TO_GRID` 远程开关，Provider `stb.c`，键
  `androidSnapToGrid`；
  `resources/res/xml/core_remoteconfig__remote_config_defaults.xml:94-97`
  默认值 **true**（随正式版开启，非实验暗门）。
- `ac4.Y` = `SHAPE_EDIT_SNAPPING` 为控制点/顶点编辑独立的第二个开关
  （Harmony 无对应交互面，见差异登记）。

### 候选生成 `q7j.a(x09, cmb, set, cxc)`

- 纸张网格：`n3a.GRID`（ordinal 2）→ `p3a`，水平/垂直网格线逐个生成
  `ijd(y, GRID_LINE, seg, 12)` / `kjd(x, GRID_LINE, seg, 12)`；
  `n3a.DOTS`（ordinal 1）→ `o3a`，格点交点生成
  `jjd(point, GRID_INTERSECTION)`；其余纸张（LINES/PLAIN 等）→ `q3a`
  空候选。间距取 `flairSpacing`（pt），由 `i8j.c(w,h,spacing,centered,
  bleeds,true)` 生成线位——与 `PaperRenderer.gridPositions` 同一数学。
- 元素候选：遍历未选中且 bounds 与可视区相交的元素，`q7j.b` 取锚点
  （无轮廓点时 `fi3.c` = bounds 四角）→ `jjd(OBJECT_CORNER)`；`d()` 取
  元素中心 → `kjd(cx)`+`ijd(cy)`（OBJECT_CENTER，guide 为贯穿元素的
  线段）；四条边 → `ijd/kjd`（OBJECT_EDGE，guide 即边线段）。
- 候选阈值：`jjd.a()=6pt`，OBJECT_CENTER=6pt，OBJECT_EDGE=8pt，
  GRID_LINE=12pt。

### 吸附决策 `m91.o` + `xe8.R`

- `m91.o(anchor, delta, dragPoints)`：拖拽侧锚点 = `fi3.c` 四角 +
  `fi3.b` 中心（平移会话），各点加位移后与全部候选比较。
- `m91.j`：`jjd` 点候选 x/y 双轴测试；`ijd` 水平线仅 y；`kjd` 垂直线
  仅 x；判定 `|delta| <= 候选阈值`（构造 `m91` 时已把 pt 阈值 ÷ zoom
  换算到文档坐标）。
- `xe8.R`：每轴各保留一个胜者——`fjd.I` 优先级更高者胜
  （GRID_LINE=1、OBJECT_EDGE=1、GRID_INTERSECTION=2、OBJECT_CORNER=2、
  OBJECT_CENTER=3），同优先级取 |delta| 更小者。
- `m91.i`：渲染的参考线 = 两轴胜者候选的非空 `b()` 线段（网格线与点
  候选 `b()` 返回 null，即只吸附不画线）。

### 消费方 `avc`

- `avc.g(...)` 移动会话：`enh.b` → `m91.o`，拖动对象整体平移时吸附。
- `avc.h(...)` 控制点/形状编辑会话：`enh.c`，受 `ac4.Y` 门控。

## Harmony 落地

- `core/model/OriginalSnapGuides.ets`：
  - `originalSnapGridCandidates(template, spacingPt, w, h, centered,
    bleeds, visible)` — 仅 GRID/DOTS 产生候选，与渲染同源的网格线位
    数学（含 centered/bleeds 偏移），按可视区过滤；
  - `originalSnapCandidatesForElementBounds(bounds)` — 每元素 4 角点 +
    2 中心线 + 4 边线共 10 候选；
  - `originalSnapMoveAnchors(bounds)` — 四角 + 中心 5 锚点；
  - `planOriginalSnapMove(anchors, dx, dy, candidates, zoom)` —
    `xe8.R` 胜者选择 + `m91.i` 参考线段收集；阈值换算
    `pt × POINTS_TO_PAGE_UNITS / zoom`（原版文档坐标即 pt，Harmony 页
    面单位为 96/72·pt）。
- `NoteCanvasView.ets`：`selectionDrag` 移动与抬手收尾两处调用
  `planSelectionSnap(dx, dy)`，以 `moveSelected(dx+snap.dx,
  dy+snap.dy)` 应用修正；候选每步重建（网格静态、未选元素静态），
  按当前可视区过滤；命中线段的参考线以 `theme.accent`、
  `1.5/zoom` 屏宽恒定线宽绘制于变换后画布；拖拽结束/取消清空。

## 差异登记（fail-closed）

- 原版元素锚点 `q7j.b` 可返回旋转/复杂轮廓的描点表（非 bounds 四角）；
  Harmony 元素无独立旋转字段（变换已烘入 bounds），一律用四角——语义
  等价于原版无轮廓点分支 `fi3.c`。
- 原版控制点/顶点编辑吸附（`avc.h` + `ac4.Y`）无对应物：Harmony 选区
  无顶点/控制点编辑面，不移植（而非近似模拟）。
- 原版网格线/点候选命中后不画参考线（`b()` 为 null）；Harmony 同样只
  绘制元素边/中心线段，与 `m91.i` 一致。
