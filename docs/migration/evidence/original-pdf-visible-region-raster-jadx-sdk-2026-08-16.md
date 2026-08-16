# 原版 PDF 可见区倍率栅格：JADX / Harmony SDK 证据

## 来源

- APK：`C:\Users\Cisco He\Desktop\Notability\Notability_1.0.3\com.gingerlabs.notability.apk`
- SHA-256：`3C616F6ED15B4DA14108A66B67A480BBA5789916A901FCDF7DE5192FA55B674B`
- 反编译目录：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- Harmony SDK：`C:\Program Files\Huawei\DevEco Studio\sdk\default\hms\ets\api\@hms.officeservice.pdfservice.d.ts`
- 本地官方 API HTML：`C:\Program Files\Huawei\DevEco Studio\plugins\openharmony\ohos-info-center-view\static\hos\JsEtsAPIReference\zh-cn_topic_0000002450645964.html`
- 日期：2026-08-16

本证据承接 Phase 256 发现的 deferred：原版实际笔记 PDF renderer 不是取得一个默认整页 bitmap 后永久缩放，
而是按请求区域和输出倍率重新 raster。Harmony 实现必须恢复该行为，但不能据此直接创建高倍整页巨型位图。

## `sba`：先并集请求区域，再按区域乘倍率分配 Bitmap

`sba.java:162-190`：

```java
if (list.isEmpty()) {
    return null;
}
ArrayList arrayList = new ArrayList(cu1.H0(list, 10));
Iterator it = list.iterator();
while (it.hasNext()) {
    arrayList.add(new fi3(((iba) it.next()).c));
}
...
while (it2.hasNext()) {
    next = new fi3(fi3.j(((fi3) next).a, ((fi3) it2.next()).a));
}
cmb cmbVar2 = ((fi3) next).a;
int iY0 = m18.y0(fi3.f(cmbVar2) * f);
...
int iY1 = m18.y0((f2 - cmbVar2.b) * f);
...
Bitmap bitmapCreateBitmap = Bitmap.createBitmap(iY0, iY1, Bitmap.Config.ARGB_8888);
```

结论：原版把所有请求 page rect 做并集，只为该并集分配 `round(width×scale) × round(height×scale)` 的
ARGB bitmap；空请求直接返回 null。它不是按当前 PDF 整页尺寸无条件分配。

`sba.java:14` 还声明 `hy0(83886080, 4)`，说明原版在共享 renderer 层有 80 MiB 级缓存预算。该值不能直接
照搬为 Harmony 单张 PixelMap 上限：Harmony 还同时持有 PixelMap、ImageBitmap、Canvas cache 与缩略图。

## `iy9`：输出倍率进入 DPI，页面顶部坐标转换到 PDF 底部坐标

`iy9.java:391-405`：

```java
if (iY0 % 180 == 0) {
    d3 = d;
} else {
    d3 = d2;
}
d4 = d24 / d3;
d5 = f5;
d6 = d4 * d5;
d7 = d6 * 72.0d;
PDFDraw.SetDPI(pDFDraw.J, d7);
PDFDraw.SetRotate(pDFDraw.J, iY0 / 90);
```

页面到笔记的缩放和 consumer 输出倍率共同形成 PDF DPI；rotation 只接受 90 度整数档。

`iy9.java:408-458`：

```java
cmbVarI = ba6.i(cmbVar3, f10, (float) d8, iY0);
...
double d25 = d10 / d4;
double d26 = d12 / d4;
...
d15 = d2 - d26;
d16 = d2 - d25;
...
double d28 = 1.0d / d6;
Rect.Set(r13.b.I,
    d17 + d21,
    (d15 - d28) + d29,
    d17 + d19 + d28 + d21,
    d16 + d29);
```

结论：请求矩形先按 cardinal rotation 映回 PDF local space，再用 `pageHeight - y` 把顶部原点坐标转换成
PDF 底部原点坐标；`1 / outputScale` 形成一个输出像素量级的边缘扩张，避免裁剪接缝。

`iy9.java:466-495` 随后执行 `PDFDraw.SetClipRect()`，只取得 clip 后 bitmap，再画入目标 bitmap；这与
“整页先 raster 再裁图”不同。

## `ba6`：四种 cardinal rectangle 映射

`ba6.java:2225-2243`：

```java
if (i == 0) return cmbVar;
if (i == 90) {
    return new cmb(cmbVar.b, f2 - cmbVar.c, cmbVar.d, f2 - cmbVar.a);
}
if (i == 180) {
    return new cmb(f - cmbVar.c, f2 - cmbVar.d, f - cmbVar.a, f2 - cmbVar.b);
}
if (i == 270) {
    return new cmb(f - cmbVar.d, cmbVar.a, f - cmbVar.b, cmbVar.c);
}
```

Harmony `PdfRasterPlan` 的 0/90/180/270 inverse mapping 逐式对应这四个分支。背景最终旋转继续由既有
Canvas transform 负责，因此传给 PDFKit 的 `PdfMatrix.rotate` 固定为 0，避免 PDFKit 与 Canvas 双重旋转。

## `lze`：consumer 分别取得显示倍率和 viewport scale

`lze.java:52-73` 同时取得 `this.Q.a` 与 `aa6.e0(x09)`/默认 `m09.b.d()`，并把两者传进 PDF work item。
结合 `sba/iy9` 可确认 renderer 需要 consumer 输出倍率，而不是一个永久固定的默认 PDF bitmap。

Harmony 主画布以 `viewport.zoom × vp2px(1)` 表示目标物理输出倍率；缩略图没有交互 viewport，使用
`pageTransform.scale` 表示 page-to-output pixel scale。

## Harmony PDFKit 契约

SDK `@hms.officeservice.pdfservice.d.ts:1732-1773`：

- `PdfMatrix.x` 是距左边缘坐标；
- `PdfMatrix.y` 是距底边缘坐标；
- width/height 描述页面矩形；
- rotate 描述 90 度档旋转。

本地官方 HTML 进一步明确 x/y/width/height 的单位均为 Points，并在 API 18 示例中用
`page.getWidth()/getHeight()` 构造全页 matrix。

SDK `:1894-1905` 提供：

```ts
getAreaPixelMap(matrix: PdfMatrix, bitmapwidth: number,
  bitmapHeight: number, isGray: boolean, drawAnnotations: boolean): image.PixelMap;
```

因此 Harmony 可以把 PDF Points clip 与输出 bitmap 像素尺寸分开指定，等价承载原版的 clip + DPI 行为。

## Harmony 受控适配与风险

- 可见区使用 25% overscan，并额外扩张一个输出像素；120 ms debounce，手势结束立即复核。
- 单边上限 4096、总像素上限 8,388,608（RGBA 约 32 MiB），防止高倍整页 allocation。
- 输出宽高继续使用原版正数 `Math.round(logicalSize × scale)`；若两个维度独立 round 后仅因取整略超总像素
  上限，则在同一 hard cap 内收敛到最大的可用倍率，不以 `floor` 偷换原版规则。
- 新 raster 完成前保留旧 raster；generation guard 丢弃迟到结果，成功交换后释放旧 ImageBitmap/PixelMap。
- `getAreaPixelMap()` 抛错时回退 `getPagePixelMap()`，PDF 背景不会因区域 API 差异完全消失。
- 预算受限概览缩进到小区域时，按“新区域在同一预算下可达到的实际倍率”决定重载；不能只比较历史请求倍率，
  否则低清概览会被永久误复用。
- PDF 文件自身的内建 page rotation、PDFKit 区域像素边缘和真实设备内存曲线仍需设备像素验收；静态证据不能
  替代这三项运行态结论。
