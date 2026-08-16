# Phase 256 修复总结：原版 PDF 页面 Native 资源生命周期

## 基线与目标

- 基线提交：`e02724f fix(rendering): restore tape zoom raster buckets`
- 目标：继续边修边审 PDF/Image background 链路，严格对照原版 1.0.3，修复可由静态证据确认的资源所有权缺口；不启动设备、模拟器、虚拟机、真机或 Hypium。

## 发现

`PdfBackgroundLoader.renderLocalPage()` 原先用
`document.getPage(pageInAsset).getPagePixelMap()` 链式取得页面像素。代码只保留 PixelMap，`finally` 仅执行
`PdfDocument.releaseDocument()`，因此无法调用 SDK 明确要求的 `PdfPage.release()`。主画布快速切页和缩略图批量生成都会重复进入该路径。

## 原版与平台证据

- 原版 `ko8.java:368-386`：每次 `PdfRenderer.openPage()` 后，成功和异常路径都通过 `rh8.q()` 关闭 page。
- 原版 `rh8.java:2224-2233`：`rh8.q(AutoCloseable, Throwable)` 是带 suppressed-exception 语义的清理边界。
- 原版 `fr1.java:108-149`：逐页 page close 完成后，才关闭 renderer 与文件描述符。
- Harmony SDK API 21 `@hms.officeservice.pdfservice.d.ts:1780-1963`：`PdfPage` 单独提供 `release()`，与 `PdfDocument.releaseDocument()` 是两个层级。

详见 `docs/migration/evidence/original-pdf-page-native-lifecycle-jadx-sdk-2026-08-16.md`。

## 实际修改

### 生产代码

- `note/src/main/ets/core/adaptation/PdfBackgroundLoader.ets`
  - 显式保存 `pdfService.PdfPage`；
  - 先通过 page 生成 PixelMap；
  - `finally` 始终先尝试 page release，再尝试 document release；
  - 两层释放错误分别捕获和记录，任一失败不阻止另一层，也不覆盖已经成功生成且交给调用者管理的 ImageBitmap/PixelMap。

共享清理函数使用两个显式 release 回调，而不是让 PDFKit 平台类匹配自定义结构接口。首次 clean 主 HAP 构建正是因此捕获 `arkts-no-structural-typing`；改为回调后保持可测性，同时符合 ArkTS 名义类型规则。

### Fixture / replay

- 新增 `note/src/test/PdfResourceLifecycle.test.ets` 并注册到 `List.test.ets`：
  - page→document 顺序；
  - 未取得 page 时仍释放 document；
  - page release 抛错后 document 仍执行；
  - document release 抛错只形成诊断，不外抛。
- 新增 `docs/migration/replays/d02-pdf-page-native-lifecycle.mjs`。
- 更新 `d02-pdf-background.mjs`，删除已过期的链式 page 获取断言，改为显式句柄和两层 release。

### 文档

- 新增 `ADR-0234-original-pdf-page-native-lifecycle.md`；
- 更新 ADR-0049、ADR-0150、Phase 173 Report、两份修复总纲及累计修复进展。

## 验证

- 生命周期专项 replay：`D02_PDF_PAGE_NATIVE_LIFECYCLE_REPLAY_OK TOTAL=8 FAILED=0`。
- PDF loader 边界 replay：`TOTAL=6 FAILED=0`。
- PDF background 主 replay：`D02_PDF_BACKGROUND_REPLAY_OK ... pdfkit-editor-thumbnail-package=closed`。
- 全量桌面 replay：`REPLAY_FILES=241 FAILED=0`。
- `hvigorw --no-daemon clean`：`BUILD SUCCESSFUL in 1 s 733 ms`。
- clean 后 `note@ohosTest`：`BUILD SUCCESSFUL in 6 s 972 ms`。
- 同一次 clean 后 `note@default`：`BUILD SUCCESSFUL in 46 s 883 ms`。
- `git diff --check` 通过，仅有项目既有 LF→CRLF 提示。
- 未启动设备、模拟器、虚拟机、真机或 Hypium。

## 边修边审的新发现

原版实际笔记 PDF background renderer 不是“整页固定 bitmap 再缩放”。`iy9/sba` 会把当前输出倍率用于 DPI，按相交页面区域建立目标 Bitmap，并设置 clip 后 raster。当前 Harmony loader 没有 viewport/output scale 参数，仍取得默认整页 PixelMap 后由 Canvas 缩放。

该差异会影响高倍清晰度和大页面内存，但不能在没有验证 PDFKit `PdfMatrix` 坐标、rotation/margins 映射和缓存上限时直接改成 8× 整页位图。它已登记为后续独立修复边界，不因本阶段的生命周期闭环被误报完成。

## 仍需设备验收

- 含真实 PDF 的连续切页、快速往返和批量缩略图 native 内存曲线；
- page/document release 异常的实际 SDK 行为；
- 四种 rotation、非零 margins 与 pending/corrupt PDF；
- 25%/100%/400% zoom 下的 PDF 像素清晰度与 visible-region cache 峰值。

T-042 APK 版本追踪仍严格保留为整个 Goal 最后一项。届时必须另写中文 Report，并把追踪文档／工具的功能、入口、阅读顺序和新版 APK decompile/diff 流程归纳进 Wiki、技术/API 文档与新手入门。
