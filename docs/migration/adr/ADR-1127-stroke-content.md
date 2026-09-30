# ADR-1127：笔画内容三分类 + ViewportState

## 状态

已接受（Phase 1183）。

## 决策

`pwd` 可绘 3 子型实名保留：**BezierStrokeContent**（
贝塞尔）、**CentralPathStrokeContent**（中线）、
**PencilStrokeContent**（铅笔 splat 点阵）—— 三种
tessellation 策略 → Harmony `drawing.Path`/点精灵；
`t0g`=`ViewportState` 相机字段语义保留（双 zoom/双
rect/暂态变换/dpi）。

## 理由

toString 实名泄漏：`BezierStrokeContent`/
`CentralPathStrokeContent`/`PencilStrokeContent(splats)`/
`ViewportState(zoom,pageWidthRelativeZoom,
functionalViewportRect,visibleViewportRect,
areTransformsTransient,density)`。

## 后果

Harmony 渲染：3 笔画 tessellation 策略 + ViewportState
相机 + ContentInputs 输入 + SceneRenderer 帧 ——
场图拓扑与原图精确对齐。
