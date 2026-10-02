# ADR-1389：lsf 形状顶点拖拽（ttf ControlPointDrag / guf.c / rsm.c）

## 状态

已实施（Phase 1454），含登记差异。

## 背景

1.4.2 选区变换会话族 `xtf`/`vtf`/`wtf`/`ttf` 的最后一员：
`ms1.java:243` 在 lsf 单形状选区的顶点命中时构造 `ttf`
（ControlPointDrag），携原始形状定义快照 + 顶点序号 +
原始变换三元组（origin/page/rotation）。`guf.c` 每帧将
`cur − dragStart` 世界增量反旋转入形状局部系，经 `rsm.c`
按类型改写控制点后由 `ybn.F` 替换页元素。

Harmony 此前仅有 Phase 1451 的顶点圆点**渲染**，圆点不可拖
——顶点拖拽整体缺失。

## 决定

- 新增顶点拖拽会话（`vertexDrag*` 六字段），命中在
  `tryStartSelectionResize` 之前（对齐 ms1 命中序），门槛=
  lsf 单形状（`!supportsDeselectMode` && 唯一形状 && 无组/
  无锁/无照片导入冲突）。
- 命中：`44/zoom` 半边长的轴对齐方框，作用于 `shapeVertexDots`
  产出的世界顶点经选区旋转反变换后的局部坐标。
- 编辑：世界增量按 `shapeVertexRotation` 反旋转入局部系后
  调用 `vertexDraggedShape`：
  - LINE：端点直移；控制点支按 `rsm.c` —— cp2 存在时
    `4/3` 系数（三次）否则 `2`（二次）；直线退化
    （cp1==start && cp2==end 或 cp1==null）端点拖动时
    重合控制点跟随端点；
  - ELLIPSE：基向点序 [0=top,1=bottom,2=left,3=right]，
    拖边移动对侧固定（center±Δ/2、radius±Δ/2），
    正圆两轴等比；
  - POLYGON：顶点直移。
- 形状经 `cloneShapeElement` 深拷贝后改写 +
  `recomputeShapeBounds`，逐帧替换 `shapes[id]`，
  `updateSelectionOverlay()`+`renderFrame()` 即时刷新。
- 提交/取消：UP 时 `vertexDragChanged` 则并入一次撤销组；
  取消恢复 `vertexDragOrigShape` 快照（=`ttf.e`
  originalDefinition 语义）；选区态保留
  （=`ttf.h` initialSelectionState）。

## 登记差异（不声称等价）

1. **正多边形规整约束未实现**：`rsm.c` l4g 支含 `oem.a`
   规范坐标系 + `fil.a`/`zB` 规整逻辑（正多边形拖拽顶点时
   受限保持规整形态），反编译未能完整解码——Harmony 顶点
   自由直移，正多边形可能被拖成不规则形。
2. **邻边/页框吸附未实现**：`guf.c` 拖拽点在应用增量前经
   多边形邻边对齐吸附与页框吸附两级修正——Harmony 无吸附。
3. **命中域为方框而非圆**：原版 `Math.abs(dx)<f9 &&
   Math.abs(dy)<f9` 轴对齐方框（88/zoom 边长），与视觉圆点
   不同形——按原版语义保留方框判定。

## 后果

- lsf 单形状选区下顶点圆点可拖拽重构形状（线端点/控制点、
  椭圆基向点、多边形顶点），取消恢复原状、提交入撤销栈。
- 正多边形规整与吸附差异显式登记，后续若完整解码
  `oem.a`/`fil.a`/`zB` 可补齐。

## 验证

- `d02-original-shape-vertex-drag.mjs` 23 项（门槛/命中序/
  44÷zoom/反旋转/三型编辑/界重算/快照取消/差异登记断言）。
