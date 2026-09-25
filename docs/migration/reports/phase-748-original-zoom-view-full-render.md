# Phase 748：原版 Zoom View 放大面全页渲染对齐（vgg）

> 日期：2026-09-25
> 证据：`docs/migration/evidence/phase-748-original-zoom-view-full-render.md`
> ADR：`docs/migration/adr/ADR-0696-original-zoom-view-full-render.md`
> Replay：`docs/migration/replays/d02-original-zoom-view.mjs`（68 pins，全绿）

## 背景

Phase 747 移植 Zoom View 时登记了一条近似：放大面只渲染笔画层
（`strokes` + `liveStroke` 直绘）。复核 `vgg.java` 构造函数发现原版
Zoom View 注入 `oze/fvb/uke/hnf/gc9/cga` 六个依赖——即整页内容渲染栈，
放大面呈现的是与主画布同一条管线的**全量页面内容**。本 Phase 修正该近似。

## 原版证据（decompiled_1.0.3）

- `vgg.java`：Zoom View 呈现器注入整页渲染栈（渲染会话/元素绘制器/位图
  资源/层管理），说明放大面 = 主画布管线输出 + 放大变换；
- `ggg.d magnification=5.0f` + `ggg.c sourceRectDocPx`：变换模型为
  `scale(mag) ∘ translate(-srcX·mag, -srcY·mag)` 后的整页直绘。

## 移植内容

| 模块 | 变更 |
|------|------|
| `NoteZoomView.ets` | 删除自带 `StrokeCanvasPainter`/`strokes`/`liveStroke`/`pageWidth`/`pageHeight`，新增 `renderContent(renderCtx, rawCtx, mag)` 回调；组件仍持有放大变换与前进区覆盖层 |
| `NoteCanvasView.ets` | `renderOrderedElements` 新增 `renderZoom` 形参（默认 `viewport.zoom`）；新增 `renderZoomPanelContent`（纸面/PDF 底图 + 有序全元素 + zoom 活动笔画置顶）；`renderFrame` 在 ZOOM 激活时 `zoomPaintTick++` 做内容镜像 |

## 语义对齐

- 放大面现在呈现：纸面底纹/PDF 底图、按 z-order 的墨迹/文本/形状/图片/
  数学块、audio-ink 播放灰显、正在书写的 zoom 活动笔画（置顶）；
- 撤销/重做、导入、元素增删、页面设置等一切主画布重绘即时镜像到放大面；
- 输入/提交/undo/持久化路径不变（仍走主画布同一管线）。

## 差异登记（详见 ADR-0696 §近似与边界）

1. 放大面不走 `StrokeLayerManager.composite` 位图缓存层，按序直绘——语义
   等价，主画布性能路径不变；
2. 含 partial-eraser 笔画的页面在放大面不经离屏混合层，极端叠加下混合
   效果可能有轻微差异；
3. Phase 747 其余登记近似（180dp→180vp 等）沿用。

## 验证

- 专项 `d02-original-zoom-view.mjs` 68/68（含 Phase 748 新 pins）；
- 全量 Desktop Replay 见提交；
- `note@default` / `note@ohosTest` 双 HAP 构建成功。
