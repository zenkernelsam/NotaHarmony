// Phase 643 — 分享面板 PDF 行点亮：整册逐页栅格化导出单个 PDF。
// 原版证据（decompiled_1.0.3）：
//   s6d.PDF 枚举（atc case4 渲染 ui_designsystem__share_pdf 图标）；
//   b7d 多选默认 PDF（list.size()>1 ? s6d.PDF : s6d.LINK）；
//   y59.a 对笔记页集合调 b(s6d.PDF, listL0, …) —— 上游 PDF 导出覆盖
//   整册页；y59.b 编码细节 JADX 未反编译，Harmony 采最小合法 PDF
//   （每页一张满幅 DCTDecode JPEG，见 ADR-0610）。
// Harmony 对齐：
//   * PagePdfExporter.buildPdf：PDF 1.4，Catalog→Pages→每页
//     Page+Contents+Image XObject；MediaBox 按 mm→pt（72/25.4）写
//     物理页尺寸；/Filter/DCTDecode 直通 JPEG；内容流
//     `q W 0 0 H 0 0 cm /Im0 Do Q` 满幅铺图；xref/trailer 完备；
//   * 栅格复用 ThumbnailRenderer.renderPageExport（×2 ≈192dpi、
//     亮主题、全元素栈），逐页 packToData(image/jpeg q92)；
//   * 预算闸门：512 页 / 单页 32MB / 整册 256MB；
//   * 保存管线与 NoteExporter/PageImageExporter 同构（临时文件 →
//     DocumentViewPicker → 分块复制 → 清理）；
//   * EditorToolbar PDF 行点亮 → onSharePdf →
//     NotePage.shareNoteAsPdf（pages 快照序 = 原版页序）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const s6d = fs.readFileSync(`${originalRoot}s6d.java`, 'utf8');
const atc = fs.readFileSync(`${originalRoot}atc.java`, 'utf8');
const b7d = fs.readFileSync(`${originalRoot}b7d.java`, 'utf8');
const y59 = fs.readFileSync(`${originalRoot}y59.java`, 'utf8');

const pdfExporter = fs.readFileSync('note/src/main/ets/data/PagePdfExporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}

// --- 原版证据 ---
check(s6d.includes('PDF(R.string.ui_share__chip_pdf'),
  's6d enumerates the PDF share format');
check(atc.includes('R.drawable.ui_designsystem__share_pdf'),
  'atc renders the pdf share icon');
check(b7d.includes('list.size() > 1 ? s6d.PDF : s6d.LINK'),
  'b7d defaults multi-selection export to PDF');
check(y59.includes('return b(s6d.PDF, listL0, mapSingletonMap, file, null, null, false, true, null, null, lk9Var);'),
  'y59.a exports the page list through s6d.PDF');

// --- Harmony：PDF 组装器 ---
check(pdfExporter.includes("out.text('%PDF-1.4\\n%\\xE2\\xE3\\xCF\\xD3\\n')") ||
  pdfExporter.includes("'%PDF-1.4"),
  'pdf output carries the PDF-1.4 header');
check(pdfExporter.includes('1 0 obj\\n<</Type/Catalog/Pages 2 0 R>>'),
  'object 1 is the catalog pointing at the pages tree');
check(pdfExporter.includes('2 0 obj\\n<</Type/Pages/Kids[') &&
  pdfExporter.includes(']/Count ${pages.length}>>'),
  'object 2 is the pages tree over all page objects');
check(pdfExporter.includes('/Type/Page/Parent 2 0 R/MediaBox[0 0 ${wPt} ${hPt}]'),
  'each page carries a physical MediaBox');
check(pdfExporter.includes('const MM_TO_PT: number = 72 / 25.4;'),
  'page size converts mm to pdf points at 72/in');
check(pdfExporter.includes('/XObject<</Im0 ${5 + i * 3} 0 R>>') &&
  pdfExporter.includes('/Subtype/Image') &&
  pdfExporter.includes('/Filter/DCTDecode'),
  'each page embeds its raster as a DCTDecode image xobject');
check(pdfExporter.includes('`q ${wPt} 0 0 ${hPt} 0 0 cm /Im0 Do Q\\n`'),
  'the content stream paints the image full-bleed');
check(pdfExporter.includes('xref\\n0 ${objectCount + 1}') &&
  pdfExporter.includes('pad10(offset)') &&
  pdfExporter.includes('startxref'),
  'the xref table and trailer are emitted with padded offsets');
check(pdfExporter.includes('MAX_PAGE_COUNT: number = 512') &&
  pdfExporter.includes('MAX_PAGE_JPEG_BYTES: number = 32 * 1024 * 1024') &&
  pdfExporter.includes('MAX_TOTAL_PDF_BYTES: number = 256 * 1024 * 1024'),
  'pdf assembly enforces page-count and byte budgets');
check(pdfExporter.includes('invalid pdf page count') &&
  pdfExporter.includes('invalid pdf page'),
  'invalid inputs fail closed during assembly');

// --- Harmony：保存管线与接线 ---
check(pdfExporter.includes('new picker.DocumentViewPicker(context)') &&
  pdfExporter.includes('documentPicker.save(saveOptions)') &&
  pdfExporter.includes('.pdf'),
  'pdf export saves through the system picker with a .pdf suffix');
check(pdfExporter.includes('fileIo.unlinkSync(tmpPath)') &&
  pdfExporter.includes('fileIo.fsyncSync'),
  'temporary pdf is fsynced then cleaned up');
check(toolbar.includes("ShareFormatRow($r('app.string.share_pdf'), 'pdf', true)"),
  'the pdf format row is enabled');
check(toolbar.includes('onSharePdf: (pageIndexes: number[] | null, password: string | null) => void') &&
  toolbar.includes('this.onSharePdf(this.sharePageIndexes, this.sharePassword);'),
  'the pdf row dispatches the page set + password to onSharePdf');
check(notePage.includes('onSharePdf: (pageIndexes: number[] | null, password: string | null) => {') &&
  notePage.includes('this.shareNoteAsPdf(pageIndexes, password);'),
  'NotePage wires onSharePdf');
check(notePage.includes('private shareNoteAsPdf(pageIndexes: number[] | null, password: string | null): void {') &&
  notePage.includes('const pages: PageInfo[] = this.resolveSharePages(pageIndexes);'),
  'shareNoteAsPdf snapshots the selected page set');
check(notePage.includes('renderer.renderPageExport(this.noteId,\n            this.persistence, page, theme, db, PAGE_EXPORT_SCALE)') &&
  notePage.includes("format: 'image/jpeg'") &&
  notePage.includes('EXPORT_JPEG_QUALITY'),
  'each page rasterizes at export scale and packs to jpeg');
check(notePage.includes('await pixelMap.release();') &&
  notePage.includes('await packer.release();') &&
  notePage.includes('await renderer.dispose();'),
  'pixelmap, packer and renderer are released around the loop');
check(notePage.includes('new PagePdfExporter()') &&
  notePage.includes('exporter.exportPdf(context, imagePages,'),
  'assembled pages go through PagePdfExporter');
check(notePage.includes('widthMm: page.widthMm') &&
  notePage.includes('heightMm: page.heightMm'),
  'pdf pages keep the physical page dimensions');

console.log(`D05_ORIGINAL_SHARE_PDF_REPLAY_OK TOTAL=${total} FAILED=0`);
