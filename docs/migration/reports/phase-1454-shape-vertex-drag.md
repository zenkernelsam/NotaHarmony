# Phase 1454 报告：lsf 形状顶点拖拽（ttf / guf.c / rsm.c）

## 触发

Phase 1453 解码变换会话族时确认 `ttf`（ControlPointDrag）未移植
——Harmony 的 lsf 顶点圆点（P1451）只能看不能拖。

## 原版证据链

1. **`ms1.java:243`**：lsf + 形状成员 + 顶点命中 → `new ttf(...)`
   携 stateId/dragStart/controlPointIndex/shapeId/
   originalDefinition/originalOrigin/originalPage/
   originalRotation/transientOperationId/initialSelectionState。
2. **顶点命中**：tap 反旋转入局部系后逐顶点测轴对齐方框，
   半边长 `guf.l/zoom` = `44/zoom`；命中序先于角柄/旋转柄。
3. **`guf.c`**：每帧 `cur−dragStart` 世界增量 → `fq9.n0` 反旋转
   入局部系（拖拽前可选经邻边对齐 + 页框吸附）→ `rsm.c` 产新
   定义 → `ybn.F` 应用；编辑恒作用于原定义快照。
4. **`rsm.c` 逐型语义**：
   - LINE(q89)：i=0 动 start、i=末 动 end、中间 i=1 动控制点
     （cp2 存在→`4/3` 三次系数；否则→`2` 二次）；直线退化
     （`cp1==null || cp1==start&&cp2==end`）端点拖动时重合
     控制点跟随；
   - ELLIPSE(k4g)：i=0/1/2/3 = top/bottom/left/right 基向点，
     拖边随指针、对侧固定（center、radius 各取半增量）；
     正圆两轴等比；
   - POLYGON(l4g)：顶点直移；另有 `oem.a`/`fil.a`/`zB`
     正多边形规整约束未完整解码。
5. **会话收尾**：`initialSelectionState` 保留选区；`ybn.F`
   逐帧替换，手势结束一次历史提交。

## Harmony 修改（NoteCanvasView.ets）

- 会话字段 `vertexDrag*`×6 + `shapeVertexRotation`；
- `tryStartShapeVertexDrag`：lsf 单形状门槛 → `shapeVertexDots`
  世界顶点 → 反旋转局部系 ±`44/zoom` 方框命中；
- `applyVertexDrag`/`vertexDraggedShape`：世界增量反旋转 →
  `cloneShapeElement` 逐型改写 → `recomputeShapeBounds` →
  替换元素 + 覆盖层/画布刷新；
- 分发序：顶点命中先于 `tryStartSelectionResize`（两 touchDown
  面）；move 两支接入；up 并入 drag/resize 提交支
  （`vertexDragChanged` 开门一次撤销）；cancel 恢复快照并清态。

## 登记差异（ADR-1389）

- 正多边形规整约束（`oem.a`/`fil.a`/`zB`）未实现——顶点自由直移；
- 邻边/页框吸附（`guf.c` 前置修正）未实现；
- 命中域为原版方框语义（88/zoom 边长），非圆点视觉形。

## 验证

- `d02-original-shape-vertex-drag.mjs`：23 项绿。
- 全量基线 / 双 HAP：随提交前流程执行。
