# ADR-0234：恢复原版 PDF page Native 生命周期

- 状态：Accepted
- 日期：2026-08-16
- 关联：ADR-0049、ADR-0150、M2-R-04、Phase 256

## 问题

`PdfBackgroundLoader` 通过 `document.getPage(...).getPagePixelMap()` 链式取得 PDF 页面像素，只保留 PixelMap，并在 `finally` 中释放 `PdfDocument`。Harmony SDK 明确要求 `PdfPage.release()`；页面句柄被丢弃后无法按契约释放。

## 原版依据

1.0.3 `ko8.java:368-386` 对每次 `PdfRenderer.openPage()` 都在成功/异常路径关闭页面；`rh8.java:2224-2233` 是带 suppressed-exception 处理的 `AutoCloseable` 清理；`fr1.java:108-149` 进一步证明逐页关闭先于 renderer/file descriptor 关闭。

## 决策

1. `PdfBackgroundLoader` 显式持有 `pdfService.PdfPage`，先取 page，再生成 PixelMap。
2. `finally` 统一调用 `releasePdfNativeResources(page, document)`，始终先尝试 `page.release()`，再尝试 `document.releaseDocument()`。
3. 两个释放动作分别捕获错误并返回诊断，page 释放失败不得阻止 document 释放；清理异常也不得覆盖已经成功生成、仍由调用者持有的 ImageBitmap/PixelMap。
4. Editor 与 Thumbnail 已分别通过 generation/finally 释放最终 ImageBitmap/PixelMap，本阶段不改变其所有权。

## 不在本阶段处理

原版 `iy9/sba` 按 viewport 输出倍率设置 PDF DPI，并按相交区域裁剪 raster；Harmony 当前仍使用默认整页 PixelMap。该差异需单独设计 zoom/crop cache，避免在本次资源修复中猜测 PDFKit 坐标与创建高倍整页巨型位图。

## 验证

- ArkTS fixture 固定 page→document 顺序、无 page 时仍释放 document、page release 失败后仍释放 document，以及 document release 错误不外抛。
- `d02-pdf-page-native-lifecycle.mjs` 固定显式 page 句柄、无链式泄漏和 finally 清理边界。
- 专项 replay 为 `TOTAL=8 FAILED=0`，全量桌面 replay 为 `REPLAY_FILES=241 FAILED=0`。
- clean 后 `note@ohosTest` 与 `note@default` 均 `BUILD SUCCESSFUL`。
- 真实 PDF 连续切页/缩略图内存曲线仍需设备验收。
