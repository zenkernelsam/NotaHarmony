# ADR-0235：按原版恢复 PDF 可见区动态倍率栅格

## 状态

Accepted - Phase 257（2026-08-16）

## 背景

Phase 256/ADR-0234 修复了 `PdfPage` native 生命周期，但 `PdfBackgroundLoader` 仍只取得默认整页
PixelMap，再由 Canvas 随 viewport 缩放。高倍 zoom 会放大既有低清像素；若简单改成 8× 整页 raster，A3、
横向页面或高 Density 设备又会制造不可控的巨型 PixelMap。

原版 1.0.3 `sba/iy9` 已证明正确模型是：合并 consumer 请求区域，按输出倍率为该区域分配 bitmap，设置 PDF
DPI 与 clip 后 raster。Harmony PDFKit 的 `PdfMatrix + getAreaPixelMap()` 可表达同一边界。

## 决策

- 新增纯逻辑 `PdfRasterPlan`：从 page-space 可见矩形生成 PDF Points matrix、page-space 目标矩形与输出
  bitmap 尺寸；非法或完全不可见请求返回 null/抛出明确错误，不进入 native API。
- 主画布通过共享 `CanvasViewport.visibleCanvasRect()` 取得可见 page-space；目标倍率为
  `viewport.zoom × vp2px(1)`。缩略图使用 `fitPageInThumbnail().scale`，只请求 300×400 输出实际需要的分辨率。
- 可见区在 page-space 扩张 25% overscan，并增加一个输出像素边缘；平移/缩放期间使用 120 ms debounce，
  gesture end/cancel 与画布尺寸变化立即复核。
- 0/90/180/270 背景矩形先 inverse-map 到未旋转 PDF local space；margins 定义 content rect；顶部原点的
  normalized y 转换为 PDF 底部原点 matrix y。
- `PdfMatrix.rotate` 固定为 0。既有 `PaperRenderer` Canvas transform 继续独占背景 rotation 与 margins，
  cropped bitmap 按 plan 的 local destination rect 绘制，禁止两套旋转叠加。
- 单张 raster 单边最多 4096，总像素最多 8,388,608（RGBA 约 32 MiB）。plan 同时记录请求倍率与实际预算
  倍率；coverage 比较新区域在当前预算下可达到的实际倍率，既允许预算封顶请求稳定复用，也允许小区域恢复细节。
- 异步 reraster 期间保留当前 READY bitmap；generation/page/lifecycle guard 丢弃迟到结果，成功交换后才释放
  旧 ImageBitmap/PixelMap。页面完全离开可见区可使用 READY/null，平移回来后重新请求。
- `getAreaPixelMap()` 失败时回退 `getPagePixelMap()`；原有 page→document、ImageBitmap→PixelMap 释放协议继续
  由 ADR-0234 和 loader caller 所有权负责。

## 后果

- PDF 在 zoom/pan 后可按真实输出倍率恢复清晰度，不再永久放大默认整页 PixelMap。
- 主画布不会为不可见页面区域付出高倍 allocation；overscan 降低连续小平移的重载频率。
- 缩略图不再先生成默认整页 bitmap 再缩到 300×400。
- 与原版 80 MiB 共享 renderer cache 不做逐字节照搬；Harmony 使用更保守的单张 32 MiB hard cap，以覆盖
  PixelMap、ImageBitmap、Canvas cache 同时存在的峰值。
- PDF 文件自身 page rotation、区域 API 像素边缘、快速 pinch/pan 抖动及 native 内存曲线仍需设备验收。
  Phase 258 后更正：M2-R-04 的 retained transfer/dirty-region 静态实现已闭环，仍开放的只是设备帧时、长时
  内存、裁剪边缘和 native 峰值验收。
- Phase 259 已把 viewport 上限按原版恢复为 10×。PDF plan 会继续按真实输出倍率请求并受 4096 单边/
  8,388,608 像素 hard cap 约束；1000% 下的实际 bounded scale、边缘与内存必须设备验证，不能把 viewport
  可达 10×解释为 PDF 一定生成 10× raster。

## 验证契约

- ArkTS fixture 覆盖 margins/full matrix、顶部→底部 y、四向 inverse mapping、side/pixel budget、overscan
  coverage、预算受限概览恢复细节、页面完全不可见。
- replay 固定 PDFKit area API、zero rotation、full-page fallback、cropped destination、旧图保留、120 ms debounce、
  thumbnail fitted scale 与 fixture 注册。
- clean 后串行构建 `note@ohosTest`、`note@default`；不启动设备、模拟器、虚拟机、真机或 Hypium。

Phase 257 实际结果：专项 `TOTAL=13 FAILED=0`，全部 `d02` replay 为 `REPLAY_FILES=242 FAILED=0`；
`hvigorw --no-daemon clean`、clean 后 `note@ohosTest` 与 `note@default` 均 `BUILD SUCCESSFUL`。
