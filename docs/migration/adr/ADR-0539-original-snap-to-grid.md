# ADR-0539：原版吸附对齐（SNAP_TO_GRID 移动拖拽）

- 日期：2026-09-22
- 状态：已采纳（含 fail-closed 差异登记）

## 背景

原版 `ac4.S`（SNAP_TO_GRID，`androidSnapToGrid` 远程默认 true）在选区
移动拖拽中把元素吸附到纸张网格线/点阵交点与其他元素的边角/边/中心，
并绘制命中的对齐参考线段。前期审计一度认为 Harmony 缺控制点/顶点编辑
而无法等价移植；进一步解码 `m91.o`/`avc.g` 后确认：移动会话本身即有
完整吸附语义（`fi3.c` 四角 + `fi3.b` 中心作锚点），与控制点会话
（`avc.h`/`ac4.Y`）相互独立——移动路径可独立等价移植。

## 决策

1. 新增 `core/model/OriginalSnapGuides.ets` 纯逻辑层：
   - 候选类型按原版 `ljd` 三型建模：点（双轴）、水平线（仅 y）、垂直线
     （仅 x）；
   - `fjd.I` 优先级与 `jjd/ijd/kjd` 阈值（6/6/8/12pt）原样保留；
   - 网格候选数学与 `PaperRenderer.gridPositions` 同源，保证吸附线恰落
     在已绘制的网格线上；
   - `planOriginalSnapMove` 复刻 `xe8.R` 每轴胜者规则与 `m91.i` 参考线
     段收集。
2. `NoteCanvasView` 在 `selectionDrag` 的移动与抬手两处接入：先按当前
   选区 bounds 生成 5 锚点，收集可视区内网格 + 未选元素候选，算出修正
   量后叠加进 `moveSelected`；命中的参考线段以主题 accent 色绘制，
   拖拽结束/取消即清空。

## 后果与差异登记

- 元素候选一律以 bounds 四角为锚点（原版无轮廓点时的 `fi3.c` 分支）；
  Harmony 元素无独立旋转字段，语义等价。fail-closed 登记。
- 控制点/顶点编辑吸附（`avc.h` + `ac4.Y`）不移植：Harmony 无对应交互
  面，不做近似模拟。
- 网格线与点候选命中后不画线（`b()` 为 null），与 `m91.i` 一致；可见
  参考线仅元素边/中心线段。
- 吸附始终生效，与原版远程默认 `androidSnapToGrid=true` 对齐；未加设置
  开关（原版亦无用户可见开关，属远程旗标）。
