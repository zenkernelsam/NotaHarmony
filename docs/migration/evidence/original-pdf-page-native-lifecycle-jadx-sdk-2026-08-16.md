# 原版 PDF page Native 生命周期证据（2026-08-16）

## 结论

原版 1.0.3 与 Harmony PDFKit 都把“文档”和“单页”定义成两个独立 native 资源。每次取得页面对象后，必须先释放页面，再释放文档。旧 `PdfBackgroundLoader` 只释放 `PdfDocument`，通过链式调用丢失 `PdfPage` 句柄，属于确定的资源所有权缺口。

## 原版 1.0.3

### `ko8.java:368-386`

- 缓存或创建 `PdfRenderer`；
- `pdfRenderer.openPage(pageIndex)` 取得 `PdfRenderer.Page`；
- 调用 `nti.U(page, targetSize)` 生成 Bitmap；
- 成功路径执行 `rh8.q(pageOpenPage, null)`；
- 异常路径也执行 `rh8.q(pageOpenPage, throwable)` 后重新抛出。

### `rh8.java:2224-2233`

`rh8.q(AutoCloseable, Throwable)` 是 Kotlin `use`/try-with-resources 的反编译形态：无主异常时直接关闭；已有主异常时关闭失败作为 suppressed exception 合并。它证明 page close 不是可选缓存优化。

### `fr1.java:108-149`

原版枚举 PDF 页面尺寸时，对每个 `openPage()` 结果逐页关闭，随后再关闭 `PdfRenderer` 与 `ParcelFileDescriptor`；成功和异常路径都遵守相同层级顺序。

## Harmony SDK 6.0 API 21

本机 SDK：`C:\Program Files\Huawei\DevEco Studio\sdk\default\hms\ets\api\@hms.officeservice.pdfservice.d.ts`。

- `PdfDocument.releaseDocument()`：`480-503`；
- `PdfDocument.getPage(index): PdfPage`：`548-555`；
- `PdfPage.getPagePixelMap()`：`1875-1881`；
- `PdfPage.release()`：`1958-1963`。

因此 `getPagePixelMap()` 返回 PixelMap 并不免除 `PdfPage.release()`。

## 移植侧旧现场

`PdfBackgroundLoader.renderLocalPage()` 原先直接执行：

```text
document.getPage(pdf.pageInAsset).getPagePixelMap()
```

页面句柄没有保存，`finally` 仅调用 `document.releaseDocument()`。主画布快速切页与缩略图批量生成都会重复进入该路径。

## 边修边审新增边界

原版实际笔记背景 renderer `iy9/sba` 还会按当前输出倍率设置 DPI，并只渲染相交区域；Harmony 当前仍把默认整页 PixelMap 缩放到页面。这是清晰度/内存架构的独立后续项，不能借本次生命周期修复冒充完成。
