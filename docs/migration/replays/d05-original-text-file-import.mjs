// Replay fixture — Phase 654：独立文本文件导入（原版 dv5 默认分支 →
// tf4.x0 UTF-8 → tu5 → yq8.f → dhj.p0 → te0：haj.a 建页 +
// kci.b 文本实体 → haa.INSERT_STRING 落寄存器位 0；空文件跳过）。
// 静态断言原实现证据 + Harmony NoteImporter 的对齐实现。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';

const dv5 = fs.readFileSync(`${originalRoot}sources/defpackage/dv5.java`, 'utf8');
const tu5 = fs.readFileSync(`${originalRoot}sources/defpackage/tu5.java`, 'utf8');
const yq8 = fs.readFileSync(`${originalRoot}sources/defpackage/yq8.java`, 'utf8');
const dhj = fs.readFileSync(`${originalRoot}sources/defpackage/dhj.java`, 'utf8');
const te0 = fs.readFileSync(`${originalRoot}sources/defpackage/te0.java`, 'utf8');
const zq9 = fs.readFileSync(`${originalRoot}sources/defpackage/zq9.java`, 'utf8');
const haa = fs.readFileSync(`${originalRoot}sources/defpackage/haa.java`, 'utf8');
const i58 = fs.readFileSync(`${originalRoot}sources/defpackage/i58.java`, 'utf8');

const importer = fs.readFileSync('note/src/main/ets/data/NoteImporter.ets', 'utf8')
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

// --- 原版证据：dv5 默认分支 → tu5 → dhj.p0 → te0 ---
check(i58.includes('new i58("*/*")'),
  'original i58.c picker type accepts */* (import then sniffs MIME)');
check(dv5.includes('nj3 nj3Var2 = nj3.txt') &&
  dv5.includes('String strX0 = tf4.x0(file2, ej1.a)') &&
  dv5.includes('file2.delete()') &&
  dv5.includes('new tu5(new o88(ttfVarX2, nj3Var2, nj3Var2, drfVar2.a, 1, 32), strX0)'),
  'dv5 default branch: nj3.txt → tf4.x0 UTF-8 read → temp delete → tu5(text)');
check(tu5.includes('public final String K'),
  'tu5 carries only the decoded string payload');
check(yq8.includes('uu5Var instanceof tu5') && yq8.includes('return dhj.p0'),
  'yq8.f routes tu5 text payloads to dhj.p0');
check(dhj.includes('tu5 tu5Var = (tu5) uu5Var') &&
  dhj.includes('tu5Var.K.length() != 0') &&
  dhj.includes('new te0(tu5Var, i3)') &&
  dhj.includes('Empty text file, skipping import') &&
  dhj.includes('return dca.c'),
  'dhj.p0: non-empty text → te0 op; empty → log + dca.c no-op');
check(te0.includes('haj.a(cxcVar, null, 1, oz9.UNBOOKMARKED, 16)') &&
  te0.includes('kci.b(null, ((tu5) obj).K, null)'),
  'te0: haj.a UNBOOKMARKED page + kci.b(null, text, null) entity');
check(zq9.includes('mx7Var.put(npbVar.b(f46.class), haa.INSERT_STRING)') &&
  haa.includes('INSERT_STRING((byte) 8)'),
  'f46 text entity journals as haa.INSERT_STRING (type 8)');
check(dv5.includes('drfVar2.a, 1, 32'),
  'o88 descriptor records one page for the imported text note');

// --- Harmony 实现对齐：选择器/分发 ---
check(importer.includes("'.txt'") && importer.includes('IMPORTED_TEXT_SUFFIXES'),
  'picker filters cover .txt (nj3.txt is the only plain-text import type)');
check(importer.includes('isImportedTextFileName(fileName)') &&
  importer.includes('importTextFromBytes(bytes, fileName)'),
  'importFromFile dispatches .txt to importTextFromBytes');

// --- Harmony 实现对齐：te0 落库结构 ---
const body = section(importer, 'private async importTextFromBytes(',
  '// 我方格式导入');
check(body.includes('bytesToString(data)'),
  'text decodes via UTF-8 (tf4.x0 parity)');
check(body.includes('text.length === 0') &&
  body.includes("'空文本文件，未导入'"),
  'empty text file skips import like the original dca.c no-op');
check(body.includes('createNoteWithMeta('),
  'imported text note uses createNoteWithMeta (no stray bootstrap page)');
check(body.includes('PageElementKind.TEXT') && body.includes('zIndex: 0') &&
  body.includes('pageIndex: 0'),
  'single Letter page hosts exactly one TEXT element at z-index 0');
check(body.includes('size: PaperSize.LETTER') && body.includes('template: PaperTemplate.PLAIN') &&
  body.includes('background: originalDefaultNoteBackground()'),
  'imported page is Letter/PLAIN/portrait with the default note background');
check(body.includes('widthMm: IMAGE_IMPORT_PAGE_WIDTH_PT * POINTS_TO_MM'),
  'page is the shared m09.b Letter 612x792pt size');
check(body.includes('removeFailedImport(createdNoteId)'),
  'failed text import cleans the partially-written note');
check(body.includes('await NoteImporter.importMutex.lock()'),
  'text import serializes with the shared import mutex');

// --- Harmony 实现对齐：文本块几何与默认值 ---
const geom = section(importer, 'function buildImportedTextElement(',
  '\n}');
check(geom.includes('blockWidth: width') && geom.includes('IMAGE_IMPORT_PAGE_WIDTH_PT'),
  'text block spans the 612pt Letter page width (page text register)');
check(geom.includes('lines * Math.fround(TEXT_IMPORT_FONT_SIZE + 8)') &&
  geom.includes('Math.max(40,'),
  'block height reuses the line-count measure rule (min 40)');
check(geom.includes('contentLeftInset: TEXT_IMPORT_LEFT_INSET') &&
  geom.includes('contentTopInset: TEXT_IMPORT_TOP_INSET') &&
  geom.includes('contentRightInset: TEXT_IMPORT_RIGHT_INSET') &&
  geom.includes('contentBottomInset: TEXT_IMPORT_BOTTOM_INSET'),
  'BlockCommon insets mirror the original defaults (5/3/5/10)');
check(geom.includes('fontSize: TEXT_IMPORT_FONT_SIZE') &&
  geom.includes('fontColor: TEXT_IMPORT_FONT_COLOR'),
  'default font 17 / black like kci.b(null, text, null) default style');
check(geom.includes('richText: text') && geom.includes('textOrigin: { x: 0, y: 0 }') &&
  geom.includes('corner: 0') && geom.includes('textWrap: 0') &&
  geom.includes('enableCaption: false'),
  'plain INSERT_STRING text at register origin, SQUARE/PIXEL_ALIGN defaults');
check(geom.includes('element.bounds = textBlockWorldBounds(element)'),
  'bounds computed through the canonical textBlockWorldBounds');
check(geom.includes("id: `imported-text-"),
  'imported text element gets a dedicated id prefix');

console.log(`D05_ORIGINAL_TEXT_FILE_IMPORT_REPLAY_OK TOTAL=${total} FAILED=0`);
