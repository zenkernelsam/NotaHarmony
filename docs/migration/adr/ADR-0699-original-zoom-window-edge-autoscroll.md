# ADR-0699：原版 Zoom 窗口边缘自动滚动（bfg）

- 状态：Accepted
- 日期：2026-09-25
- 关联：ADR-0695/0696/0697/0698（Zoom View 系列）、
  `phase-751-zoom-window-edge-autoscroll.md`

## 背景

`gfg.a` 除安装 `efg→dfg` 拖拽手势外，还挂载 `bfg`——一个
withFrameNanos 帧循环协程，在覆盖层按压态下逐帧工作：指针进入画布
左右 30dp 边缘带时视口自动平移（带内 100dp/s、越过边缘 500dp/s），
源窗口同步平移保持吸附指针（`scrollBy(−iY0)` + `setSourceRect(rect+
iY0/zoom)`）。Phase 750 移植覆盖层时未含此子行为。

## 决定

1. `onZoomWindowTouch` Move 分支末尾评估指针横向位置：
   距右缘 <30vp → 向右滚（指针出界 >edge → 500vp/s，带内 100vp/s）；
   左缘镜像。带外/无拖拽 → 停表。
2. 滚动用 `setInterval` 16ms 逐帧驱动（ArkUI 无公共 vsync 回调的
   等价近似）；dt 用 `Date.now()` 差值封顶 100ms。
3. 每帧 `viewport.panBy(-dxVp, 0)` + `clampZoomSource(sourceX +
   dxVp/zoom)`——窗口随视口平移保持指针吸附，X-only 与原版一致。
4. 手势结束/取消/工具切换统一经 `endZoomWindowDrag` →
   `stopZoomWindowEdgeScroll` 停表。

## 近似登记

- 两档速度判定的确切参照（`a76` 矩形语义）有歧义 → 按"带内慢速、
  越界快速"经典交互实现。
- 帧粒度 16ms 定时器近似 vsync 回调。
- 视口平移沿用既有不钳制约定；窗口页内夹取。

## 后果

- 拖窗口/把手到画布左右边缘时页面自动让路，窗口持续跟随——
  长距离移动窗口不再需要反复拖放。
- MOVE 与 RESIZE 手势均生效（原版按压态即激活，不分模式）。
- 无新依赖；专项 Replay pins 扩展验证接线结构。
