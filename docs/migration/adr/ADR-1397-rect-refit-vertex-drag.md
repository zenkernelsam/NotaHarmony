# ADR-1397：l4g 矩形多边形顶点拖拽走旋转矩形重拟合（rsm.c + oem.a + fil.a/b）

- 状态：已采纳
- Phase：1462（结清 Phase 1454 登记差异「oem.a 规范系 + fil.a/zB
  规整约束未完全解码」）

## 背景

Phase 1454 移植 `ttf` 顶点拖拽时，`rsm.c` 的 `l4g`（多边形）支只做到
顶点直移；当时 `oem.a` 与 `fil.a/zB` 的语义未完全解码，登记为差异。

本 Phase 完成解码：`fil.a` = 四角质心等距 ±0.1%（矩形/菱形类四边形），
`fil.b` = |w−h|≤0.1%·max（正方形），`oem.a` = RotatedRect 解码
（θ=边0→1方向角 + 反旋 AABB 校验 + 非矩形回退规整 + 角0/2中点）。
`rsm.c` 对 `fil.a` 命中的多边形顶点拖拽不是直移顶点，而是：

1. 顶点绕矩形中心反旋 `−θ` 入矩形局部系；
2. 拖拽角在 AABB 角序 `[BL,BR,TR,TL]`（`p0.a()`）中定位 `i3`；
3. 局部增量 `rot((dx,dy),−θ)` 加在 `i3` 角；两邻角沿共享边轴跟随
   （`i±1` 按奇偶取 moved/own 分量），对角不动——**保持矩形性**；
4. `fil.b`（原 AABB 近方）时按 `p0.e={-1,+1,-1,+1}` 对角符号把增量
   主轴主导、副轴按比例耦合；
5. 重旋 `+θ` + 二次 `oem.a` 归一化；正方形最终再以输出对角
   `[(i+2)%4 → i]` 重建**轴对齐正方形**（边长
   `max(0.5,(|dx|+|dy|)/2)`，旋转归零）。

## 决策

按上述数学 1:1 移植到 `NoteCanvasView` 模块级函数
`decodeRotatedRect`/`rectRefitVertexDrag`/`filSquare`，并把
`filQuadrilateral` 补全为完整 `fil.a`（等距判定）——同步收紧
`snapVertexDragPoint` 的 guf.c 吸附门（非矩形四边形恢复邻边射线吸附）。
`vertexDraggedShape` POLYGON 支：`fil.a` 命中走重拟合，否则直移。

## 差异登记

- `oem.a` 反编译的 AABB 角匹配循环受 JADX 糖化干扰，按「全部 AABB 角
  均被反旋角点命中」语义实现（`p0Var` 非空 = all-match）——与 Kotlin
  `all{…any{…}}` 惯用展开一致。
- 正方形支重建的是**轴对齐**正方形（拖拽结果旋转归零）——原版行为，
  非缺陷。

## 验证

`d02-original-shape-vertex-drag.mjs` 41/41；全量 Replay 1304/1304；
`note@default`/`note@ohosTest` clean 构建通过。
