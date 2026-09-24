// Replay fixture — Phase 656：Office/RTF/Apple 文档导入 fail-closed 登记。
// 原版 nj3 的 doc/docx/ppt/pptx/ppsx/xls/xlsx/rtf/rtfd/key/pages 十一种类型在
// jv5 中全部经 fca.f（via/em8 加载框架 → PDFTron r8d 文档）转换为 PDF 后走
// su5 管线（与 Phase 652 PDF 导入同一路径）。Harmony PDFKit 仅提供
// pdfService.loadDocument/convertToImage，无 Office→PDF 转换引擎，故这十一
// 种类型不进入 fileSuffixFilters，经分享/Intent 到达时落入 importFromData
// 非 .note 分支 fail closed。静态断言证据与 fail-closed 实现形态。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';

const nj3 = fs.readFileSync(`${originalRoot}sources/defpackage/nj3.java`, 'utf8');
const jv5 = fs.readFileSync(`${originalRoot}sources/defpackage/jv5.java`, 'utf8');
const yq8 = fs.readFileSync(`${originalRoot}sources/defpackage/yq8.java`, 'utf8');

const importer = fs.readFileSync('note/src/main/ets/data/NoteImporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}

// ── 原版证据：nj3 声明全部十一种 PDFTron 转换类型 ──────────────────────────
for (const token of [
  'doc("application/msword")',
  'docx("application/vnd.openxmlformats-officedocument.wordprocessingml.document")',
  'ppt("application/vnd.ms-powerpoint")',
  'pptx("application/vnd.openxmlformats-officedocument.presentationml.presentation")',
  'ppsx("application/vnd.openxmlformats-officedocument.presentationml.slideshow")',
  'xls("application/vnd.ms-excel")',
  'xlsx("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")',
  'rtf("text/rtf")',
  'rtfd,',
  'key("application/vnd.apple.keynote")',
  'pages("application/vnd.apple.pages")',
]) {
  check(nj3.includes(token), `nj3 declares ${token.split('(')[0]}`);
}

// ── 原版证据：jv5 经 fca.f 把文档加载为 r8d 再统一包装 su5(nj3.pdf) ──────
const fcaCalls = (jv5.match(/fcaVar\d*\.f\(/g) || []).length;
check(fcaCalls >= 4, `jv5 fca.f loader call sites >=4 (got ${fcaCalls})`);
const su5Count = (jv5.match(/new su5\(new o88\(ttfVar, nj3\.pdf/g) || []).length;
check(su5Count >= 4, `jv5 su5(nj3.pdf) sites >=4 (got ${su5Count})`);
check(yq8.includes('uu5Var instanceof su5'), 'yq8.f routes su5 payloads');

// ── Harmony fail-closed：选择器不收十一种类型 ────────────────────────────
const filterStart = importer.indexOf('selectOptions.fileSuffixFilters');
check(filterStart !== -1, 'picker fileSuffixFilters present');
const filterEnd = importer.indexOf('];', filterStart);
const filterBlock = importer.slice(filterStart, filterEnd);
for (const suffix of ['.doc', '.docx', '.ppt', '.pptx', '.ppsx', '.xls', '.xlsx',
  '.rtf', '.rtfd', '.key', '.pages']) {
  check(!filterBlock.includes(`'${suffix}'`), `picker excludes ${suffix}`);
}

// ── Harmony fail-closed：无 Office/RTF 转换路径，未知类型落 importFromData ──
check(!/convertOffice|officeToPdf|convertToPdf|\.docx?['"]|\.rtfd?['"]/i.test(importer),
  'no Office/RTF conversion path in NoteImporter');
const dispatchStart = importer.indexOf("endsWith('.pdf')");
const dispatchEnd = importer.indexOf('return await this.importFromData(bytes)', dispatchStart);
check(dispatchStart !== -1 && dispatchEnd > dispatchStart,
  'dispatch falls through to importFromData');
const dispatchBlock = importer.slice(dispatchStart, dispatchEnd);
check(dispatchBlock.includes('isImportedImageFileName') &&
  dispatchBlock.includes('isImportedTextFileName') &&
  dispatchBlock.includes('isImportedAudioFileName'),
  'all implemented non-PDF branches precede the fail-closed fallback');

// ── Harmony fail-closed：importFromData 仅接受 .note zip，其余报错 ────────
const dataStart = importer.indexOf('async importFromData');
check(dataStart !== -1, 'importFromData present');
const dataSlice = importer.slice(dataStart, dataStart + 2500);
check(dataSlice.includes('ZipReader.parse') && dataSlice.includes('manifest.json'),
  'importFromData only attempts .note zip decoding');

console.log(`D05_ORIGINAL_OFFICE_FILE_IMPORT_FAIL_CLOSED_REPLAY_OK TOTAL=${total} FAILED=0`);
