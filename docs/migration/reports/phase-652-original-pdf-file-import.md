# Phase 652：独立 PDF 文件导入（jv5 PDF 分支）

日期：2026-09-24
接续：Phase 651（批操作一步撤销）
ADR：ADR-0619
证据：`docs/migration/evidence/original-pdf-file-import-jadx-2026-09-24.md`
专项 Replay：`docs/migration/replays/d05-original-pdf-file-import.mjs`（32 项）

## 原版行为（硬证据）

- `i58.java:6`：文件选择器类型 `i58.c = new i58("*/*")` —— 任意类型进入后
  由 `jv5` 按 MIME 嗅探分发。
- `nj3.java`：可导入类型约 30 种，`pdf("application/pdf")` 在列。
- `jv5.java` PDF 分支：`o88(ttf, nj3.pdf, nj3, str 文件名, 页数, 32)` 描述符
  → `fca.f(absolutePath, z39)` PDFTron 打开 → `su5(o88, r8d 文档句柄,
  页列表)` → `nv5` 结果 —— 整文档一个资产，每页一条 wz9 寄存器。
- `mw3.java`：空笔记 action row 的 Import File 走同一入口。
- `xw9.java`/`decodeOriginalPdfAsset`：pdf 寄存器 `layoutBehavior`
  flatbuffer 默认 = `FIT_AND_CROP_BOX`。

## Harmony 实现

1. **选择器**：`importFromFile` 的 `fileSuffixFilters` 扩为
   `['.note', '.pdf']`（`DocumentViewPicker` 只能按后缀过滤，
   其余原版类型保持 fail-closed）。库 FAB「Import File」与空笔记
   行均经 `importAndOpen → importFromFile`，自动获得 PDF 支持。
2. **嗅探分发**：字节读入后先查 `%PDF-` magic（对齐原版 MIME 嗅探），
   其次 URI `.pdf` 后缀 → `importPdfFromBytes`；magic 不符 →
   `UNSUPPORTED_FORMAT` fail-closed。
3. **解析先行（零写库验证）**：`pdfService.PdfDocument.loadDocument`
   仅接受沙箱路径 → 字节落 `assets/pending/pdf_import_*.tmp` 暂存，
   解析后删除；`getPageCount` 限 10000（原版 sw9 cropBoxes
   flatvector 上限），逐页 `getWidth/getHeight` 取可视 pt 尺寸
   并过 `pagePixelSize` 像素预算 —— 全部在写库前完成，保持
   `importOurFormat`「验证失败不写库」契约。
4. **寄存器**：每页 `background.pdf` 共享整文档 sw9 寄存器
   （`pagesConsumed=totalPageCount=N`、`pageOffset=0`、
   `cropBoxes[N]`、`pageInAsset=i`），`layoutBehavior=FIT_AND_CROP_BOX`；
   `paper/margins=null`、`rotationRadians=0`、`sourceSize=页 pt 尺寸`、
   `originalPageInAsset=i`、`bookmarked=false`、`template=PLAIN`、
   `size=inferPaperSize(pt→mm)`、方向按宽高比 —— 经
   `validatePdfBackground` 不变量校验。
5. **写库**：`importMutex` 内 `createNoteWithMeta`（导入路径，
   无默认空白页）→ `storeImportedOriginalAsset`（sha512→assetHashBits、
   `application/pdf`、字节数）→ `addImportedPage`×N；
   异常 → `removeFailedImport` 清理半成品 → `CORRUPTED`。
6. **标题**：picker URI 尾段 `decodeURIComponent` 得名去 `.pdf`
   后缀；空 stem 回退 `'导入笔记'`。
7. `inferPaperSize` 由 `OriginalPageBackgroundOperation` 导出复用，
   保持与原解码路径同一归类逻辑。

## 有意差异（fail-closed，见 ADR-0619）

- `*/*` → `['.note', '.pdf']`（picker 能力限制；Office/图片/音视频
  等其余原版类型另立后续 Phase）。
- cropBoxes 用 `getWidth/getHeight` 可视尺寸（= sourceSize = 渲染
  尺寸），保证寄存器自洽。
- 超大页（>2048px 单边 / >2M 像素）fail-closed `CORRUPTED`。

## 验证

- 专项 Replay：`D05_ORIGINAL_PDF_FILE_IMPORT_REPLAY_OK TOTAL=32 FAILED=0`。
- `d02-note-import-file-handle-lifecycle` 切片边界更新后 7/7；
  `d02-local-create-page-outbound` 调用点计数 2→3。
- 全量 Desktop Replay：537/537（见下方最终记录）。
- `note@ohosTest` / `note@default` clean HAP 构建成功（仅既有告警）。
- 未做模拟器/真机/Hypium 验证（按项目约束）。

## 遗留

- 其余原版导入类型（Office 经 PDFTron 转换、图片元素化、音频为
  Recording、视频等）仍 fail-closed，登记为后续 Phase 候选。
- PDF 内嵌注释/表单不物化（与原版 sw9 渲染语义一致：仅作页背景）。
