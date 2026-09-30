# ADR-1176：360 几何/立体数据结构

## 状态

已接受（Phase 1232）。

## 决策

`q0b` 立体 UV×mesh+`r71` 时间队列+`p0b`/`o0b` 眼 mesh
+`m40` 旋转 map → Harmony 有序 Map+XComponent 顶点
缓冲+3 立体 UV 矩阵。

## 理由

`q0b.i/j/k`=mono/top-bottom/side-by-side 3×3 UV；
`p0b`=`o0b` 左/右眼+type；`r71`/`m40` 时间→旋转/mesh
队列 —— 360 逐帧几何。

## 后果

Harmony 360 几何 = 有序 Map+顶点缓冲+UV 矩阵 ——
立体布局语义保真。
