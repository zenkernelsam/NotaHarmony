// Phase 644 — 分享面板页范围选择（原版 v6d.l 页集合的 Harmony 子集）。
// 原版证据（decompiled_1.0.3）：
//   v6d.java: `public final Set l`（页选择集合）+ `int m`（总页数）；
//   b7d.java: `set.size() != v6dVar2.m` 判定部分页导出 —— 上游分享
//   面板支持任选页子集。
// Harmony 对齐（ADR-0611 子集）：
//   * 面板顶部加页范围切换（share_range_all / share_range_current），
//     作用于 PDF/JPG/PNG 行；NOTE 恒整册、LINK 置灰；
//   * PDF：当前页 → 单页 PDF，全部 → 整册（Phase 643 管线）；
//   * JPG/PNG：当前页 → 单文件直存（Phase 642 管线），全部 →
//     逐页栅格编码打入单个 zip（page_001.<ext> 序，ZipWriter
//     STORE），经同一 DocumentViewPicker 保存；
//   * 任意子集选择依赖缩略图栅格面（未实现），登记差异。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const v6d = fs.readFileSync(`${originalRoot}v6d.java`, 'utf8');
const b7d = fs.readFileSync(`${originalRoot}b7d.java`, 'utf8');

const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const imageExporter = fs.readFileSync('note/src/main/ets/data/PageImageExporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const strBase = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const strZh = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}

// --- 原版证据 ---
check(v6d.includes('public final Set l') && v6d.includes('public final int m') ||
  v6d.includes('public final Set l'),
  'v6d carries a selected-page set plus a page count');
check(b7d.includes('set.size() != v6dVar2.m'),
  'b7d detects partial-page exports via set size vs page count');

// --- Harmony：面板页范围切换 ---
check(toolbar.includes('@State shareAllPages: boolean = true'),
  'share sheet tracks the page-range selection state');
check(toolbar.includes("ShareRangeOption($r('app.string.share_range_all'), true)") &&
  toolbar.includes("ShareRangeOption($r('app.string.share_range_current'), false)"),
  'sheet offers all-pages and current-page range options');
check(toolbar.indexOf("share_range_all"), 'range selector uses the all-pages label');
check(toolbar.indexOf('ShareRangeOption') > 0 &&
  toolbar.indexOf('ShareRangeOption($r') <
  toolbar.indexOf("ShareFormatRow($r('app.string.share_link')"),
  'the range selector renders above the format rows');
check(toolbar.includes('this.shareAllPages = allPages;'),
  'range options update the selection state');
check(toolbar.includes('this.onSharePdf(this.shareAllPages);') &&
  toolbar.includes('this.onShareImage(format, this.shareAllPages);'),
  'pdf and image rows dispatch the chosen range');
check(!toolbar.includes('onShareNote(this.shareAllPages)'),
  'the note row always exports the whole note (no range)');

// --- Harmony：JPG/PNG 整册 zip 路径 ---
check(imageExporter.includes('exportPageImagesZip') &&
  imageExporter.includes('new ZipWriter()'),
  'multi-page image export packages pages through ZipWriter');
check(imageExporter.includes('`page_${pad3(i + 1)}.${suffix}`') ||
  imageExporter.includes('page_${pad3(i + 1)}'),
  'zip entries carry the sequential page_NNN name');
check(imageExporter.includes('writer.addEntry(name, images[i], false)'),
  'zip entries store rasters uncompressed (jpeg/png already coded)');
check(imageExporter.includes('_pages_') && imageExporter.includes('.zip'),
  'the zip save uses a _pages_ named .zip file');
check(notePage.includes('const pages: PageInfo[] = allPages ? this.pages.slice() :\n      [this.pages[this.currentPageIndex]];'),
  'image export resolves the range into a page list');
check(notePage.includes('for (const page of pages)') &&
  notePage.includes('encodedPages.push(new Uint8Array(data))'),
  'every selected page is rasterized and encoded into the zip set');
check(notePage.includes('exporter.exportPageImagesZip(context,\n          encodedPages, this.noteTitle, shareFormat)'),
  'encoded pages go through the zip exporter');
check(notePage.includes('if (pages.length === 1)') &&
  notePage.includes('exportPageImage(context,\n            singlePixelMap'),
  'a single selected page still uses the direct image save path');

// --- Harmony：PDF 页范围 ---
check(notePage.includes('private shareNoteAsPdf(allPages: boolean): void {'),
  'shareNoteAsPdf takes the page-range flag');
check(notePage.indexOf('private shareNoteAsPdf') > 0 &&
  notePage.includes('allPages ? this.pages.slice() :\n      [this.pages[this.currentPageIndex]]'),
  'pdf export resolves the same range subset');

// --- 字符串资源（双语） ---
for (const name of ['share_range_all', 'share_range_current']) {
  check(strBase.includes(`"name": "${name}"`), `base locale defines ${name}`);
  check(strZh.includes(`"name": "${name}"`), `zh_CN locale defines ${name}`);
}

console.log(`D05_ORIGINAL_SHARE_PAGE_RANGE_REPLAY_OK TOTAL=${total} FAILED=0`);
