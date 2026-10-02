# Phase 1462 报告：l4g 矩形多边形顶点拖拽 = 旋转矩形重拟合（rsm.c + oem.a + fil.a/b）

## 原版行为（1.4.2 证据）

- `fil.a`（fil.java）：`size==4` 且四角到质心距²与首角相差
  ≤0.1%·max、maxDist²≥0.001 → 矩形/菱形类四边形判定。
- `fil.b`（fil.java）：`|w−h| ≤ 0.001·max(w,h)` → 正方形判定。
- `oem.a`（oem.java）：RotatedRect 解码——θ=边0→1方向角
  （`π/2−atan2(Δx,Δy)`），角点反旋 −θ 后须逐角命中 AABB
  （容差 `max(1,max(w,h))·1%`），否则输出回退为规整矩形；
  `center` = 输出角 0/2 中点。
- `p0`（p0.java）：AABB (x,y,w,h)，角序 **[BL,BR,TR,TL]**；
  `p0.e = {-1,+1,-1,+1}` 对角符号。
- `rsm.c` l4g 支（rsm.java:128-291）：`fil.a` 命中的四顶点多边形
  顶点拖拽 = **旋转矩形重拟合**，非顶点直移：
  1. 顶点绕中心反旋 −θ 入矩形局部系；
  2. 拖拽角在 AABB 角序中定位 i3（1% 容差）；
  3. 局部增量 `rot(δ,−θ)` 加在 i3 角，`i±1` 两邻角沿共享边轴跟随、
     对角固定——**矩形性保持**；
  4. `zB`（原 AABB `fil.b` 近方）：`d9=w/h`、`d10=h/w`、
     `sign=p0.e[i3]` 耦合增量分量（主轴主导）；
  5. 重旋 +θ → 二次 `oem.a` 归一化；正方形再替换为按输出对角
     `[(i+2)%4 → i]` 重建的**轴对齐正方形**（边长
     `max(0.5,(|Δx|+|Δy|)/2)`）。
- `guf.c`：`fil.a` 命中的多边形跳过 e2n.d 邻边射线吸附（矩形性由
  重拟合保持），仍走 twm.b 页/对象候选回退。

## Harmony 缺口（Phase 1454 登记）

POLYGON 顶点拖拽一律直移顶点——矩形被拖成任意四边形、正方形
对角重建语义缺失；`filQuadrilateral` 缺等距判定导致 fil.a 门
对非矩形四边形误触发。

## 实现（NoteCanvasView.ets）

- `filQuadrilateral` 补全 `fil.a` 等距判定；
- `filSquare` = `fil.b`；`rotAround` = `sem.c`；
  `aabbCorners` = `p0.a()`；
- `decodeRotatedRect` = `oem.a`（含非矩形 AABB 回退）；
- `rectRefitVertexDrag` = `rsm.c` l4g+fil.a 支全链
  （i3 命中→邻角约束→正方形耦合→重旋归一→轴对齐方形重建）；
- `vertexDraggedShape` POLYGON 支按 `filQuadrilateral` 分流。

坐标系：`applyVertexDrag` 已把世界增量反旋进形状局部系（guf.c
`fq9.n0`），与 rsm.c 的 `(f,f2)`+局部 `listC0` 同域。

## 验证

- `d02-original-shape-vertex-drag.mjs`：41/41（新增 8 项静态断言
  + 轴对齐矩形拖角可执行模型：TR 拖 (4,6) → TL.y 跟随、BR.x 跟随、
  BL 固定）。
- `note@default` clean 构建通过；全量 Replay 与 `note@ohosTest`
  见收尾验证。

## 遗留差异

- `oem.a` AABB 角匹配循环受 JADX 糖化干扰，按 `all{…any{…}}`
  语义实现（证据：p0Var 非空=全匹配路径返回 p0VarB）。
- 正方形拖角结果轴对齐（旋转归零）为原版行为，非缺陷。
