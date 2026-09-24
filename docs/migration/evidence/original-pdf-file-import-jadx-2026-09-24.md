# 原版独立 PDF 文件导入 — JADX 证据（2026-09-24）

范围：`decompiled_1.0.3` 下「Import File → PDF」链路的静态证据，支撑 Phase 652。

## 选择器与类型分发

- `i58.java:6`：`public static final i58 c = new i58("*/*")` ——
  原版文件选择器以 `*/*` 接受任意类型，导入后由 `jv5` 按 MIME 嗅探分发。
- `nj3.java`：可导入类型枚举，`pdf("application/pdf")` 在列
  （同列还有 Office/文本/Notability 封装/图片/音视频约 30 种）。
- `mw3.java`：空笔记 action row 的 Import File 走同一 `jv5` 入口。

## jv5 PDF 分支

`jv5.java`（约 230–270 行）PDF 分支：

```java
nj3 nj3Var = nj3.pdf;
o88 o88Var2 = new o88(ttfVar, nj3Var, nj3Var, str,
    ((ArrayList) adaVar.a()).size(), 32);          // 文档描述符
Object objF = fcaVar.f(absolutePath, new z39(file, 5), bv5Var);  // PDFTron 打开
return new nv5(new su5(o88Var, (r8d) obj, adaVar2.a()), …);      // 结果
```

- `o88.java`：`o88(ttf, nj3 源类型, nj3 目标类型, String 文件名, int 页数, boolean)`。
- `fca.f`：PDFTron 打开 + 读取路径，产出 `r8d` 文档句柄。
- `su5.java`：`public final r8d K`（文档句柄）+ `public final List L`（页表）
  + `public final File M` —— 导入结果一次性持有整文档与全部页。
- `nv5.java`：包装 `su5` 为导入结果。

## 页背景寄存器（sw9/wz9）

- 每页 `wz9.pageInAsset = i`；`sw9` 寄存器 `pagesConsumed = 总页数`、
  `pageOffset = 0`、`cropBoxes = 全页 CropBox 表`（整文档共享消费）。
- `xw9.java`：`DOWNSCALING_AND_MAX_BOX(0) / DOWNSCALING_AND_CROP_BOX(1) /
  FIT_AND_CROP_BOX(2)`；`decodeOriginalPdfAsset` 的 flatbuffer 默认即
  `FIT_AND_CROP_BOX`（`readUint8(1, FIT_AND_CROP_BOX)`），与 PDFTron
  「适配裁剪框」导入语义一致。
- Harmony 侧既有不变量（`validatePdfBackground`）：
  `cropBoxes.length === pagesConsumed`、`pageInAsset ∈
  [pageOffset, pageOffset+pagesConsumed)`、`pageOffset+pagesConsumed ≤
  totalPageCount` —— 整文档共享寄存器形状即上述三元组。

## Harmony 适配决策

1. **选择器收缩**：`DocumentViewPicker` 只能按后缀过滤，无法复刻 `*/*`；
   收缩到当前可物化的 `['.note', '.pdf']`，其余类型保持 fail-closed
   （原版约 30 种类型中的 Office/图片/音频/视频另立后续 Phase）。
2. **类型嗅探对齐**：进入后先查 `%PDF-` magic（对齐原版 MIME 嗅探），
   其次 URI `.pdf` 后缀；magic 不符 fail-closed `UNSUPPORTED_FORMAT`。
3. **PDFKit 对应 PDFTron**：`pdfService.PdfDocument.loadDocument` 仅接受
   沙箱路径 → 字节先落 `assets/pending` 暂存（沿用资产写者的暂存目录），
   解析后删除；`getPageCount` + 逐页 `getWidth/getHeight`（应用页内
   /Rotate 后的可视尺寸，与渲染侧 `getPagePixelMap` 同源）取得 pt 尺寸。
4. **写库**：`createNoteWithMeta`（导入路径，无默认空白页）→
   `storeImportedOriginalAsset`（sha512 → assetHashBits，`application/pdf`）
   → 每页 `addImportedPage`，页背景 = `paper:null/pdf:共享寄存器/
   rotationRadians:0/sourceSize=页 pt 尺寸/margins:null`，
   `originalPageInAsset=i`、`bookmarked=false`、`template=PLAIN`、
   `size=inferPaperSize(pt→mm)`、方向按宽高比。
5. **失败语义**：解析失败/页数越界/像素预算超限 → `CORRUPTED`
   且零写库；写库中异常 → `removeFailedImport` 清理半成品笔记
   （与 `importOurFormat` 同一事务契约）。
6. **标题**：原版 `o88` 描述符携带文件名字符串 `str`；Harmony 从 picker
   URI 尾段 `decodeURIComponent` 得名，去 `.pdf` 后缀为笔记标题。

## 已知差异（fail-closed）

- 原版 `*/*` 全类型入口 → Harmony 仅 `.note`+`.pdf`（其余类型后续 Phase）。
- 原版页尺寸取 PDFTron CropBox；PDFKit `getBox(BOX_CROP)` 可用但为保持
  寄存器自洽（cropBoxes 项 = sourceSize = 渲染尺寸），统一用
  `getWidth/getHeight` 可视尺寸。
- Harmony 页面像素预算（`pagePixelSize`：单边 ≤2048px、总像素 ≤2M）
  对超大页 fail-closed；原版无此上限（画布无法物化的页拒绝导入）。
- `PDF_IMPORT_MAX_PAGES = 10000` 对齐原版 sw9 cropBoxes flatvector 上限。
