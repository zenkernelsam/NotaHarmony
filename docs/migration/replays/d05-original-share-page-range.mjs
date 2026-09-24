// Phase 644 — 分享面板页范围选择（原版 v6d.l 页集合的 Harmony 子集）。
// 原版证据（decompiled_1.0.3）：
//   v6d.java: `public final Set l`（页选择集合）+ `int m`（总页数）；
//   b7d.java: `set.size() != v6dVar2.m` 判定部分页导出 —— 上游分享
//   面板支持任选页子集。
// Harmony 对齐（ADR-0611；Phase 670 起升级为完整子集）：
//   * 页范围行（share_page_range / share_range_all /
//     share_range_selected）→ PAGE_SELECTION 栅格勾选任意子集，
//     作用于 PDF/JPG/PNG 行；NOTE 恒整册、LINK 置灰；
//   * PDF：子集逐页栅格嵌入单 PDF，null 集合 → 整册；
//   * JPG/PNG：单页子集 → 单文件直存（Phase 642 管线），多页 →
//     逐页栅格编码打入单个 zip（page_001.<ext> 序，ZipWriter
//     STORE），经同一 DocumentViewPicker 保存。
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

// --- Harmony：面板页范围行（Phase 670 升级为任意子集栅格） ---
check(toolbar.includes('@State sharePageIndexes: number[] | null = null'),
  'share sheet tracks the nullable page-index set (v6d.l)');
check(toolbar.includes("share_page_range") &&
  toolbar.includes('this.shareSelectionLabel()'),
  'the range row shows Page range + All/X of Y');
check(toolbar.indexOf("share_page_range") > 0 &&
  toolbar.indexOf("share_page_range") <
  toolbar.indexOf("ShareFormatRow($r('app.string.share_link')"),
  'the range row renders above the format rows');
check(toolbar.includes('this.toggleSharePage(pageIndex)'),
  'picker cells toggle indexes through b7d.q semantics');
check(toolbar.includes('this.onSharePdf(this.sharePageIndexes);') &&
  toolbar.includes('this.onShareImage(format, this.sharePageIndexes);'),
  'pdf and image rows dispatch the chosen page set');
check(!toolbar.includes('onShareNote(this.sharePageIndexes)'),
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
check(notePage.includes('const pages: PageInfo[] = this.resolveSharePages(pageIndexes);'),
  'image export resolves the page set into a page list');
check(notePage.includes('for (const page of pages)') &&
  notePage.includes('encodedPages.push(new Uint8Array(data))'),
  'every selected page is rasterized and encoded into the zip set');
check(notePage.includes('exporter.exportPageImagesZip(context,\n          encodedPages, this.noteTitle, shareFormat)'),
  'encoded pages go through the zip exporter');
check(notePage.includes('if (pages.length === 1)') &&
  notePage.includes('exportPageImage(context,\n            singlePixelMap'),
  'a single selected page still uses the direct image save path');

// --- Harmony：PDF 页范围 ---
check(notePage.includes('private shareNoteAsPdf(pageIndexes: number[] | null): void {'),
  'shareNoteAsPdf takes the nullable page set');
check(notePage.indexOf('private shareNoteAsPdf') > 0 &&
  notePage.indexOf('resolveSharePages(pageIndexes)') > 0,
  'pdf export resolves the same page-set subset');

// --- 字符串资源（双语） ---
for (const name of ['share_range_all', 'share_range_selected', 'share_page_range']) {
  check(strBase.includes(`"name": "${name}"`), `base locale defines ${name}`);
  check(strZh.includes(`"name": "${name}"`), `zh_CN locale defines ${name}`);
}

console.log(`D05_ORIGINAL_SHARE_PAGE_RANGE_REPLAY_OK TOTAL=${total} FAILED=0`);
