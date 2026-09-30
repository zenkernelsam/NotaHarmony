# ADR-1272：WidthOutlineBuilder + PencilSplat

## 状态

已接受（Phase 1328）。

## 决策

变宽轮廓（法向偏移+圆头帽）+铅笔 splat 逐方法保真
—— 笔画外形算法保真。

## 理由

`WidthOutlineBuilder`（halfWidth 逐点半径+左右法向
偏移曲线+appendArc 圆头帽→闭多边形，bezierkit
attributed path）+`PencilSplatGenerator`（对照 `xaa`/
`oz5` splat 引擎——LCG 散布+压感⁵+T-033 钳制）——
笔画外形+铅笔纹理保真。

## 后果

变宽笔画轮廓+铅笔颗粒感与原版一致 —— 渲染外观保真。
