# Phase 751 证据：原版 Zoom 窗口边缘自动滚动（bfg）

> 证据基线：`decompiled_1.0.3`（JADX 输出，`C:\Users\Cisco He\Desktop\Notability\` 只读）。
> 关联：ADR-0698（源窗口覆盖层）——本 Phase 补齐其按压边缘滚动子行为。

## 1. `bfg` 方法体完整解码

`defpackage/bfg.java`（149 行，`invokeSuspend` **可反编译**）：
`gfg.a` 中以 `m18.k` 挂载的帧循环协程（`l96.s0(ctx).b(ix4)` =
withFrameNanos 逐帧回调），仅在覆盖层处于按压态时工作
（`gl8Var` Boolean + `vj8` InteractionSource pressed 检查）。

密度换算阈值（`r93.j0(dp)`，dp→px）：

```
f  = 30dp    // 边缘带宽
f3 = 100dp   // 慢速
f2 = 500dp   // 快速
```

逐帧逻辑（`afg.invoke(frameNanos)`）：

```
f8  = dt（帧间隔秒，首帧 0）
fK  = i3a.k()                       // 当前缩放系数（>0 才工作）
fH  = a76.d − pointer.h()           // 右缘距离（a76=视口/窗矩形投影）
f9  = −a76.b                        // 左缘距离（镜像分支）
speed = (dist >= 30dp) ? 500 : 100  // dp/s
iY0 = round(speed * dt)             // 本帧 px 位移
sh1.l(w66(−iY0))                    // 视口消费滚动量（反向）
ix4.invoke(fi3(rect.k(+iY0/fK)))    // → setSourceRect：窗口 doc 平移
```

语义：**窗口手势按压期间，指针进入画布左/右 30dp 边缘带时视口自动
平移**——带内 100dp/s，指针越出边缘（dist ≥ 30dp）加速到 500dp/s；
同时源窗口按 scroll/zoom 同步平移，保持吸附在指针下方（
"拖到页面边缘继续推，纸面让路、窗口跟随"的经典行为）。
仅横向分支（a76.b/.d = 左右缘），无纵向。

## 2. 与 `dfg` 的关系

`dfg`（按压拖拽状态机，未反编译）更新按压标记与指针位置状态
（`gl8Var`/`vj8`/`m6a`）；`bfg` 独立按帧消费这些状态产生产生滚动——
两者经共享 `gl8` 状态槽解耦（按压 + 指针位置 → 滚动量 →
`setSourceRect` 回调）。`gfg.d(rect, gi3)` = Rect 平移 + dock 侧约束。

## 3. Harmony 移植映射

| 原版 | Harmony（Phase 751） |
|---|---|
| `l96.s0().b` 帧循环 | `setInterval` 16ms 逐帧 tick（拖拽存续期间） |
| `f8`（withFrameNanos dt） | `Date.now()` 差值，封顶 100ms 防卡顿跳变 |
| 30dp 带 / 100dp/s / 500dp/s | `ZOOM_EDGE_SCROLL_BAND_VP=30` / `SLOW=100` / `FAST=500`（vp 等价） |
| `sh1.l(w66(-iY0))` 视口滚动 | `viewport.panBy(-dxVp, 0)` |
| `setSourceRect(rect.k(iY0/fK))` 窗口跟随 | `clampZoomSource(sourceX + dxVp/zoom, sourceY)` |
| 按压态驱动（gl8+vj8） | `zoomWindowDragMode !== 0`（MOVE/RESIZE 均生效） |

## 4. 近似登记

- 原版 `fH>=30dp→500`/`fH<30dp→100` 的两档判定映射为
  "带内 100vp/s、指针越过画布边缘 500vp/s"——`a76` 矩形的确切
  参照系（视口 vs 窗口投影）在反编译体内有歧义，按经典
  "按压越界加速"交互近似。
- 原版滚动走 `sh1` ScrollState 消费通道（可能含滚动钳制）；
  Harmony 视口平移本身不钳制（既有自由平移约定），
  窗口经 `clampZoomSource` 夹取页内。
- 帧循环粒度：原版 withFrameNanos（vsync 对齐），Harmony 用
  16ms 定时器近似。

## 5. 文件清单

- `note/src/main/ets/ui/editor/NoteCanvasView.ets`：
  `ZOOM_EDGE_SCROLL_*` 常量、`zoomEdgeScroll*` 运行时字段、
  `updateZoomWindowEdgeScroll`/`zoomWindowEdgeScrollTick`/
  `stopZoomWindowEdgeScroll`、`onZoomWindowTouch` Move 分支接线、
  `endZoomWindowDrag` 收尾停表。
