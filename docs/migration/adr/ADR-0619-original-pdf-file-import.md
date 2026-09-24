# ADR-0619 独立 PDF 文件导入（jv5 PDF 分支）

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：652
- 接续：ADR-0610（分享导出）、T-028/T-032（.note/原版 Notability 导入）
- 证据：`docs/migration/evidence/original-pdf-file-import-jadx-2026-09-24.md`

## 背景

原版 Import File（库新建菜单 + 空笔记 action row，`mw3`/`i58`）的选择器
类型为 `*/*`，导入后由 `jv5` 按 MIME 嗅探分发；其中 PDF 分支经
`o88(nj3.pdf)` 描述符 → `fca.f` PDFTron 打开 → `su5(r8d 文档 + 页表)`
→ `nv5`，产出「整文档一个资产 + 每页一条 wz9 寄存器」的笔记。

Harmony 此前 `NoteImporter.importFromFile` 的 picker 仅过滤 `.note`，
PDF 导入完全缺失；但底层已具备 `PdfBackgroundLoader`（PDFKit 渲染
sw9 寄存器页）、`storeImportedOriginalAsset`、`addImportedPage` 与
`validatePdfBackground` 全套模型。

## 决定

1. **选择器**：`fileSuffixFilters` 扩为 `['.note', '.pdf']`。Harmony
   `DocumentViewPicker` 只能按后缀过滤，无法复刻原版 `*/*`；其余
   约 30 种原版类型保持 fail-closed，另立后续 Phase。
2. **分发**：读取字节后先查 `%PDF-` magic（对齐原版 MIME 嗅探），
   其次 URI `.pdf` 后缀 → `importPdfFromBytes`；否则走既有
   `importFromData`（.note ZIP 路径）。magic 不符 →
   `UNSUPPORTED_FORMAT`，绝不把非 PDF 字节喂给 PDFKit。
3. **解析先行**：`pdfService.PdfDocument.loadDocument` 仅接受沙箱
   路径 → 字节先写 `assets/pending/pdf_import_*.tmp` 暂存
   （沿用资产写者暂存目录），解析后无论成败删除；`getPageCount`
   限 `PDF_IMPORT_MAX_PAGES = 10000`（原版 sw9 cropBoxes
   flatvector 上限），逐页 `getWidth/getHeight` 取可视 pt 尺寸，
   并逐页过 `pagePixelSize` 像素预算 —— 全部在写库前完成，
   保持与 `importOurFormat` 相同的「验证失败不写库」契约。
4. **寄存器**：每页 `background.pdf` 共享同一整文档 sw9 寄存器
   （`totalPageCount = pagesConsumed = N`、`pageOffset = 0`、
   `cropBoxes[N]`、`pageInAsset = i`），`layoutBehavior =
   FIT_AND_CROP_BOX`（flatbuffer 默认，对齐原版适配裁剪语义）；
   `paper/margins = null`、`rotationRadians = 0`、
   `sourceSize = 页 pt 尺寸`、`originalPageInAsset = i`、
   `bookmarked = false`、`template = PLAIN`、
   `size = inferPaperSize(pt→mm)`、方向按宽高比。
5. **写库**：`importMutex` 内 `createNoteWithMeta`（导入路径，
   无默认空白页）→ `storeImportedOriginalAsset`（sha512 →
   assetHashBits，`mimeType = application/pdf`，`fileSize = 字节数`）
   → `addImportedPage` × N；任一异常 → `removeFailedImport`
   清理半成品笔记后报 `CORRUPTED`。
6. **标题**：picker URI 尾段 `decodeURIComponent` 得名，
   去 `.pdf` 后缀；空 stem 回退 `'导入笔记'`。

## 有意差异（fail-closed）

- `*/*` → `['.note', '.pdf']`：picker 能力限制；Office/图片/音视频
  等其余原版类型不在本 Phase。
- CropBox 语义：原版存 PDFTron CropBox；Harmony 统一用
  `getWidth/getHeight` 可视尺寸（cropBoxes 项 = sourceSize =
  渲染尺寸），保证寄存器自洽且与 `PdfBackgroundLoader` 渲染同源。
- 超大页（超出 2048px 单边 / 2M 像素缓存预算）fail-closed
  `CORRUPTED`；原版无此上限。

## 验证

- 专项 Replay `d05-original-pdf-file-import.mjs`：32 项全绿。
- 既有 `d02-note-import-file-handle-lifecycle.mjs` 切片边界更新后 7/7。
- 全量 Desktop Replay：见 Phase 652 报告记录的最终计数。
- `note@ohosTest` / `note@default` clean HAP 构建均成功
  （仅既有告警，无新增错误）。
- 未做模拟器/真机验证（按项目约束）。
