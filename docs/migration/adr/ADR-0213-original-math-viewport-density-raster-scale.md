# ADR-0213：standalone Math bitmap 必须按 Viewport Zoom × Density 动态栅格化

## 状态

Accepted，2026-08-15。

## 问题

Harmony 的 `MathCanvasRenderer` 对主编辑器和缩略图统一固定使用 `pixelScale=2`。这虽然比 1× bitmap 更清晰，
但不是原版算法：

- 在高 Density 或放大视口中，2× 低于最终物理显示倍率，公式仍会被二次放大，细线、根号和上下标变糊；
- 在缩略图或低缩放视口中，2× 又高于实际输出倍率，浪费 Native bitmap、PixelMap 与 4 MiB LRU 预算；
- 固定倍率使缓存不能按原版的离散显示倍率复用，也无法在 zoom/Density 跨阈值时选择正确清晰度。

## 原版证据

- `t0g.toString()` 把字段 `a` 命名为 `ViewportState.zoom`，把字段 `f` 命名为 `density`。
- `r93.a()` 返回 Compose Density；`r93.j0()` 明确以 `a() * logicalValue` 转为物理像素。
- 对缺失普通反编译的方法执行 JADX 1.5.6 单类 fallback/simple 后，`aeg.invokeSuspend()` 明确调用：
  `ue4.v(..., t0g.a, t0g.f.a(), ...)`。
- `ue4.v()` 的线性输出为：
  `m18.y0(rh8.u(zoom * density, 1.0f, 4.0f) * 2.0f) / 2.0f`。
- `m18.y0(float)` 是 `Math.round(float)`，`rh8.u()` 是闭区间 clamp；结果随后传给 `G → E → p18`。
- `ue4.E()` 把 scale 纳入 standalone Math bitmap cache key，`p18` 用它同时决定 bitmap 像素尺寸和 Canvas scale。
- 完整线性摘录、APK SHA-256 与复现命令见
  `docs/migration/evidence/original-math-raster-scale-jadx-2026-08-15.md`。

## 决策

1. 新增纯函数 `originalMathRasterScale(viewportZoom, density)`，严格执行：
   `round(clamp(Float32(zoom × density), 1, 4) × 2) / 2`。
2. zoom、density 和乘积先用 `Math.fround()` 收窄，保持原版 Java/Kotlin float 边界；半步阈值不得按 ArkTS double
   任意漂移。
3. 主画布传入当前 `CanvasViewport.zoom` 与 `vp2px(1)`，使 Native bitmap 对应最终 `vp → physical px`
   的真实显示倍率。
4. 缩略图已经在固定 300×400 输出坐标中计算 `pageTransform.scale`，因此传入
   `pageTransform.scale × 1`；不得再次叠加屏幕 Density，避免把输出 PixelMap 的目标像素倍率算两次。
5. `MathCanvasRenderer.renderMath()` 显式接收量化后的 raster scale；缓存键和 Native render 必须使用同一个
   Float32 值。
6. 非有限、非正 Harmony 平台输入回退到原版最小 1×，避免把 NaN/Infinity 送入 Native；正常 viewport 和
   Density 路径不受此平台加固分支影响。
7. 保留原版 4 MiB byte-counted LRU、oversized transient texture 与 ImageBitmap/PixelMap 释放语义。

## 结果

- 主画布在 2×/3× Density 与放大 zoom 下会生成匹配物理输出的 1–4× bitmap，不再固定停在 2×。
- 缩略图通常落在原版最小 1×，减少无意义的 2× Native 分配和 cache eviction。
- 0.5 步长抑制连续 pinch zoom 引起的每帧 cache key 抖动，同时保持原版质量阶梯。
- 同一 LaTeX、block 尺寸、颜色和离散倍率继续稳定命中缓存；跨倍率只创建必要的新条目。

## 边界

- 真机仍需在 1×/2×/3× Density 和 25%–400% zoom 下核对 bitmap 尺寸、清晰度、裁切与缓存切换。
- 当前含原版 partial eraser 时会先把完整内容画入全页 `OffscreenCanvas`；该公共离屏层自身的分辨率与缩放可能
  继续限制包括 Math 在内的最终质量。本 ADR 修正 Math source bitmap 契约，不在同一批次重写全元素 tile/layer
  架构；该问题保留为后续边修边审项。
- 多窗口或运行中 Density 改变依赖 ArkUI 的重新绘制时机；每次 `renderOrderedElements()` 都重新读取
  `vp2px(1)`，不会永久缓存旧 Density。
- 本阶段不启动设备、模拟器、虚拟机或 Hypium。
