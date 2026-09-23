# 原版分享面板 PDF 整册导出 — jadx 证据（2026-09-23）

阶段：Phase 643。结论：原版分享面板 `s6d.PDF` 格式经 `y59` 对笔记页集合
导出 PDF；Harmony 现以「整册逐页栅格化 → 每页满幅 JPEG 嵌入最小合法
PDF 1.4」点亮 PDF 行（ADR-0610）。

## 原版证据（decompiled_1.0.3）

### 格式枚举与图标

`defpackage/s6d.java`：`PDF(ui_share__chip_pdf, action_pdf, ..., atc(4))`；
`atc` case4 渲染 `R.drawable.ui_designsystem__share_pdf` 图标。
格式顺序 LINK、PDF、NOTE、JPG、PNG（`s6d` 枚举声明序），PDF 位列第二。

### 默认格式策略

`defpackage/b7d.java`：`s6d s6dVar = list.size() > 1 ? s6d.PDF : s6d.LINK`
——多笔记/多页导出默认落到 PDF（LINK 单选时走链接分享）。

### 导出执行

`defpackage/y59.java`：`a(ttf, String, File, lk9)` 内部
`return b(s6d.PDF, listL0, mapSingletonMap, file, null, null, false, true, null, null, lk9Var);`
——对传入页集合按 `s6d.PDF` 走导出执行体 `b(...)`。
`y59.b` 本体 JADX 未反编译（`UnsupportedOperationException`），上游 PDF
编码实现（矢量/栅格、分页尺寸、字体嵌入）不可见；本 Phase 按最小合法
PDF 落地并在 ADR-0610 登记差异。

## Harmony 实现（本 Phase）

- 新增 `note/src/main/ets/data/PagePdfExporter.ets`：
  - `buildPdf(pages: PdfPageImage[])`：PDF 1.4 组装器。对象布局
    `1=Catalog → 2=Pages → 页 i 占 3+3i(Page)/4+3i(Contents)/5+3i(Image)`；
    `MediaBox[0 0 wMm·72/25.4 hMm·72/25.4]` 写物理页尺寸；内容流
    `q W 0 0 H 0 0 cm /Im0 Do Q` 满幅铺图；Image XObject 走
    `/Filter/DCTDecode`（JPEG 字节直通，无二次编码）；
    xref 表十字节定宽偏移 + trailer/Root 完备。
  - `exportPdf(context, pages, title)`：临时文件 → `DocumentViewPicker`
    `.pdf` 保存 → 分块复制 → fsync → 清理，与 `PageImageExporter` 同构。
  - 预算闸门：`MAX_PAGE_COUNT=512`、`MAX_PAGE_JPEG_BYTES=32MB`、
    `MAX_TOTAL_PDF_BYTES=256MB`；非法输入 fail-closed。
- `EditorToolbar`：PDF 行 `supported=true`，派发 `onSharePdf`；
  s6d 序不变（LINK 仍置灰——账号后端未备）。
- `NotePage.shareNoteAsPdf()`：`this.pages.slice()` 快照整册页序，
  逐页 `renderPageExport`（×2 ≈192dpi、亮主题、全元素栈）→
  `ImagePacker.packToData('image/jpeg', q92)` → `PdfPageImage` 收集 →
  `PagePdfExporter.exportPdf`；pixelMap/packer/renderer 在
  try/finally 中逐页释放；toast 复用 `export_done`/`export_failed`。

## 登记差异（ADR-0610）

1. 上游 `y59.b` 未反编译：是否矢量导出/字体嵌入未知；Harmony 为纯
   栅格 PDF（与 JPG 导出同分辨率策略）。
2. 页选择集合（`v6d.l`）未实现：Harmony 恒为整册导出。
3. 多笔记 PDF 合并（`b7d` `list.size()>1` 场景）无对应入口：Harmony
   面板只作用于当前打开的笔记。
4. LINK 行仍 fail-closed（账号后端依赖）。
