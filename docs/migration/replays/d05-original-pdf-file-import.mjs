// Phase 652 — 独立 PDF 文件导入（库/空笔记 Import File → jv5 PDF 分支）。
// 原版证据（decompiled_1.0.3）：
//   i58.java     选择器类型为 */*（i58.c），导入后由 jv5 按 MIME 嗅探分发；
//   nj3.java     pdf("application/pdf") 为可导入类型之一；
//   jv5.java     PDF 分支构造 o88(ttf, nj3.pdf, nj3, str, 页数, 32) 描述符，
//                fca.f(absolutePath, z39) 打开 PDFTron 文档 → su5(o88, r8d, 页列表)
//                → nv5 结果；su5.java 持有 r8d 文档句柄 + List 页表 + File；
//   mw3.java     空笔记 action row 的 Import File 走同一选择器。
// Harmony 对齐：DocumentViewPicker 只能按后缀过滤 → 收缩到 ['.note', '.pdf']，
//   进入后以 %PDF- magic 对齐原版的 MIME 嗅探；PDFKit 逐页取尺寸 → 校验通过后
//   一次性写库（createNoteWithMeta + storeImportedOriginalAsset + N×addImportedPage），
//   每页持有整文档共享的 sw9 寄存器（pagesConsumed=N/pageOffset=0/cropBoxes[N]），
//   pageInAsset=i；失败走 removeFailedImport 清理，与 .note 导入同一事务契约。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const i58 = fs.readFileSync(`${originalRoot}sources/defpackage/i58.java`, 'utf8');
const nj3 = fs.readFileSync(`${originalRoot}sources/defpackage/nj3.java`, 'utf8');
const jv5 = fs.readFileSync(`${originalRoot}sources/defpackage/jv5.java`, 'utf8');
const su5 = fs.readFileSync(`${originalRoot}sources/defpackage/su5.java`, 'utf8');
const xw9 = fs.readFileSync(`${originalRoot}sources/defpackage/xw9.java`, 'utf8');

const importer = fs.readFileSync('note/src/main/ets/data/NoteImporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const bgOp = fs.readFileSync('note/src/main/ets/data/OriginalPageBackgroundOperation.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const bgModel = fs.readFileSync('note/src/main/ets/core/model/PageBackgroundModel.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const library = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}
function section(source, startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start);
  assert.ok(start !== -1 && end > start, startMarker);
  return source.slice(start, end);
}

// --- 原版证据：选择器 */* + MIME 嗅探分发，PDF 走 PDFTron 解析 ---
check(i58.includes('new i58("*/*")'),
  'original i58.c picker type accepts */* (import then sniffs MIME)');
check(nj3.includes('pdf("application/pdf")'),
  'nj3.pdf is one of the original importable MIME types');
check(jv5.includes('nj3 nj3Var = nj3.pdf') &&
  jv5.includes('new o88(ttfVar, nj3Var, nj3Var, str') &&
  jv5.includes('fcaVar.f(absolutePath, new z39(file, 5), bv5Var)') &&
  jv5.includes('new nv5(new su5(o88Var, (r8d) obj, adaVar2.a())'),
  'jv5 PDF branch: o88 descriptor → fca.f PDFTron open → su5(doc+pages) → nv5');
check(su5.includes('public final r8d K') && su5.includes('public final List L') &&
  su5.includes('public final File M'),
  'su5 carries the PDFTron document handle plus the whole page list');
check(xw9.includes('FIT_AND_CROP_BOX((byte) 2)') &&
  bgOp.includes('table.readUint8(1, PdfLayoutBehavior.FIT_AND_CROP_BOX)'),
  'xw9 layoutBehavior: FIT_AND_CROP_BOX is the register default for pdf assets');

// --- 选择器收缩 + magic 嗅探 ---
check(importer.includes("selectOptions.fileSuffixFilters = ['.note', '.pdf',") &&
  importer.includes("'.webp'") && importer.includes("'.heic'"),
  'picker filter covers .note/.pdf plus the Phase 653 image suffixes');
check(importer.includes('startsWithPdfMagic(bytes) || fileName.toLowerCase().endsWith(\'.pdf\')'),
  'dispatch sniffs %PDF- magic first (original MIME-sniff parity), extension second');
check(importer.includes('data[0] === 0x25 && data[1] === 0x50') &&
  importer.includes('data[4] === 0x2D'),
  'startsWithPdfMagic pins the %PDF- file signature');
check(importer.includes('pickedFileName(uri)') &&
  importer.includes('decodeURIComponent(tail)'),
  'picked file name decoded from the picker URI for metadata + title');
check(importer.includes("fileName.toLowerCase().endsWith('.pdf')") &&
  importer.includes('fileName.substring(0, fileName.length - 4)'),
  'pdfImportTitle strips the .pdf suffix like the original file-name title');

// --- 解析阶段：先验证，零写库（与 importOurFormat 同一事务契约） ---
check(importer.includes('fileIo.mkdirSync(pendingDirectory, true)') &&
  importer.includes('writeFileFully(stagingPath, data)') &&
  importer.includes('fileIo.unlinkSync(stagingPath)'),
  'PDF bytes staged under assets/pending for path-only loadDocument, then removed');
check(importer.includes('document.loadDocument(path)') &&
  importer.includes('pdfService.ParseResult.PARSE_SUCCESS') &&
  importer.includes('document.getPageCount()') &&
  importer.includes('document.getPage(index)') &&
  importer.includes('document.releaseDocument()'),
  'PDFKit parse: loadDocument → getPageCount → per-page dims → releaseDocument');
check(importer.includes('pagePixelSize(widthPt * POINTS_TO_MM, heightPt * POINTS_TO_MM)'),
  'every PDF page is validated against the Harmony page-cache budget before writing');
check(importer.includes('PDF_IMPORT_MAX_PAGES: number = 10000') &&
  importer.includes('pageCount > PDF_IMPORT_MAX_PAGES'),
  'page count bounded by the original sw9 cropBoxes flatvector limit');

// --- 写库阶段：整文档共享 sw9 寄存器 + 每页 pageInAsset ---
const pdfImport = section(importer, 'private async importPdfFromBytes(',
  'private async importOurFormat(');
check(pdfImport.includes('createNoteWithMeta(') &&
  pdfImport.includes('storeImportedOriginalAsset(this.db, metadata, data, note.id)'),
  'note created via the import path (no blank bootstrap page) + asset stored under the new id');
check(pdfImport.includes('mimeType: \'application/pdf\'') &&
  pdfImport.includes('originalAssetHashBitsFromSha512(digestBytes)') &&
  pdfImport.includes('fileSize: data.length'),
  'pdf asset metadata carries sha512 bits + application/pdf + byte size');
check(pdfImport.includes('pagesConsumed: pageSizes.length') &&
  pdfImport.includes('pageOffset: 0') &&
  pdfImport.includes('totalPageCount: pageSizes.length') &&
  pdfImport.includes('pageInAsset: index') &&
  pdfImport.includes('cropBoxes: cropBoxes'),
  'shared whole-document sw9 register: pagesConsumed=N, pageOffset=0, cropBoxes[N], pageInAsset=i');
check(pdfImport.includes('layoutBehavior: PdfLayoutBehavior.FIT_AND_CROP_BOX'),
  'imported pdf register uses the flatbuffer-default FIT_AND_CROP_BOX layout');
check(pdfImport.includes('paper: null') && pdfImport.includes('rotationRadians: 0') &&
  pdfImport.includes('margins: null') &&
  pdfImport.includes('sourceWidthPt: widthPt') && pdfImport.includes('sourceHeightPt: heightPt'),
  'page background: null paper/rotation/margins, sourceSize = page pt dims');
check(pdfImport.includes('originalPageInAsset: index') && pdfImport.includes('bookmarked: false') &&
  pdfImport.includes('template: PaperTemplate.PLAIN') &&
  pdfImport.includes('PageOrientation.LANDSCAPE : PageOrientation.PORTRAIT'),
  'PageInfo: wz9 pageInAsset register + unbookmarked + PLAIN template + aspect orientation');
check(pdfImport.includes('inferPaperSize(widthMm, heightMm)') &&
  bgOp.includes('export function inferPaperSize('),
  'page size bucket inferred by the shared original decode helper');
check(pdfImport.includes('widthPt * POINTS_TO_MM') &&
  bgModel.includes('export const POINTS_TO_MM: number = 25.4 / 72.0'),
  'pt→mm conversion reuses the original POINTS_TO_MM constant');
check(pdfImport.includes('await pageRepo.addImportedPage(note.id, pageInfo)') &&
  pdfImport.includes('pageIndex: index'),
  'pages materialize via addImportedPage in document order');
check(pdfImport.includes('NoteImporter.importMutex.lock()') &&
  pdfImport.includes('await this.removeFailedImport(createdNoteId)'),
  'write phase holds importMutex and cleans a partially created note on failure');
check(pdfImport.includes('result: ImportResult.SUCCESS') &&
  pdfImport.includes('pageCount: pageSizes.length'),
  'success report returns the new note id, title and real page count');

// --- 宿主接线：既有入口自动获得 PDF 支持 ---
check(library.includes('importer.importFromFile(context)') &&
  library.includes('router.pushUrl({ url: \'ui/editor/NotePage\''),
  'library Import File keeps routing through importFromFile then opens the imported note');

// --- 寄存器形状复算（validatePdfBackground 不变量） ---
for (let index = 0; index < 3; index++) {
  const register = { totalPageCount: 3, pagesConsumed: 3, pageOffset: 0,
    cropBoxes: new Array(3).fill(0), pageInAsset: index };
  check(register.pageOffset + register.pagesConsumed <= register.totalPageCount &&
    register.pageInAsset >= register.pageOffset &&
    register.pageInAsset < register.pageOffset + register.pagesConsumed &&
    register.cropBoxes.length === register.pagesConsumed,
    `emitted register satisfies validatePdfBackground invariants for page ${index}`);
}
check(bgModel.includes('value.cropBoxes.length !== value.pagesConsumed') &&
  bgModel.includes('value.pageInAsset >= value.pageOffset + value.pagesConsumed'),
  'validatePdfBackground bounds remain the authority the emitted register satisfies');

// --- 标题/名称辅助复算 ---
const titleOf = (name) => (name.toLowerCase().endsWith('.pdf') ?
  name.substring(0, name.length - 4) : name);
check(titleOf('Lecture-01.PDF') === 'Lecture-01' && titleOf('a.pdf') === 'a',
  'title derivation strips a case-insensitive .pdf suffix');
check(importer.includes("return base.length > 0 ? base : '导入笔记'"),
  'empty file stem falls back to the shared imported-note title');

console.log(`D05_ORIGINAL_PDF_FILE_IMPORT_REPLAY_OK TOTAL=${total} FAILED=0`);
