// D02 原版段落缩进 ±1 Replay —— Phase 686
// 证据：原版 cve.java 派单 ute→m(new h5a(1))、yte→m(new h5a(-1))
// 段落级 indentLevel 增量 op；l32 case0/1 渲染 increase/decrease_indent
// 行条目（行序位于 italic 之前）。Harmony：adjustIndentLevel 复用
// draftStyles 段落键管线，钳制 >=0、level 归 0 且无其余字段时清除条目
// 保持 canonical；按钮按 l32 行序置于 bold 与 italic 之间。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const cve = fs.readFileSync(`${D}/sources/defpackage/cve.java`, 'utf8');
const l32 = fs.readFileSync(`${D}/sources/defpackage/l32.java`, 'utf8');
const stringsXml = fs.readFileSync(`${D}/resources/res/values/strings.xml`, 'utf8');
const overlay = fs.readFileSync(
  'note/src/main/ets/ui/components/TextBlockOverlay.ets', 'utf8').replaceAll('\r\n', '\n');
const renderer = fs.readFileSync(
  'note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets', 'utf8').replaceAll('\r\n', '\n');
const stringsEn = fs.readFileSync(
  'note/src/main/resources/base/element/string.json', 'utf8');
const stringsZh = fs.readFileSync(
  'note/src/main/resources/zh_CN/element/string.json', 'utf8');

let total = 0, failed = 0;
function check(cond, name) {
  total++;
  if (!cond) {
    failed++;
    console.error(`FAIL ${name}`);
  }
}

// ===== 原版证据钉 =====
check(cve.includes('nueVar.equals(ute.a)') &&
  cve.includes('m(new h5a(1))'),
  'cve: ute → h5a(+1) increase indent op');
check(cve.includes('nueVar.equals(yte.a)') &&
  cve.includes('m(new h5a(-1))'),
  'cve: yte → h5a(-1) decrease indent op');
check(l32.includes('R.string.ui_text__increase_indent') &&
  l32.includes('R.string.ui_text__decrease_indent'),
  'l32 renders increase/decrease indent rows');
check(l32.indexOf('R.string.ui_text__increase_indent') <
  l32.indexOf('R.string.ui_text__decrease_indent') &&
  l32.indexOf('R.string.ui_text__decrease_indent') <
  l32.indexOf('R.string.ui_text__italic'),
  'l32 row order: increase < decrease < italic');
check(stringsXml.includes('<string name="ui_text__increase_indent">Increase indent</string>') &&
  stringsXml.includes('<string name="ui_text__decrease_indent">Decrease indent</string>'),
  'original indent strings');

// ===== Overlay 语义钉 =====
check(overlay.includes('private adjustIndentLevel(delta: number): void') &&
  overlay.includes('const level: number = Math.max(0, (current.indentLevel ?? 0) + delta)') &&
  overlay.includes('this.draftStyles.set(paragraphIndex, next)') &&
  overlay.includes('this.draftStyles.delete(paragraphIndex)'),
  'adjustIndentLevel: ±delta clamped >=0, fields preserved, canonical empty-drop');
check(overlay.includes('this.paragraphIndexAt(this.caretOffset)') &&
  overlay.indexOf('adjustIndentLevel') < overlay.indexOf('toggleDecoratorStyle'),
  'indent applies at caret paragraph via draftStyles');
check(overlay.includes("Button($r('app.string.increase_indent'))") &&
  overlay.includes("Button($r('app.string.decrease_indent'))") &&
  overlay.includes('this.adjustIndentLevel(1)') &&
  overlay.includes('this.adjustIndentLevel(-1)'),
  'indent buttons wired to adjustIndentLevel(±1)');
check(overlay.indexOf("app.string.bold')") <
  overlay.indexOf("app.string.increase_indent')") &&
  overlay.indexOf("app.string.increase_indent')") <
  overlay.indexOf("app.string.decrease_indent')") &&
  overlay.indexOf("app.string.decrease_indent')") <
  overlay.indexOf("app.string.italic')"),
  'button order: bold < increase < decrease < italic (l32 order)');

// ===== 渲染器与字符串钉 =====
check(renderer.includes('paragraph.indentLevel ?? 0') &&
  renderer.includes('* element.fontSize * 36 / 14'),
  'renderer indents paragraph by indentLevel * fontSize * 36/14');
for (const k of ['increase_indent', 'decrease_indent']) {
  check(stringsEn.includes(`"name": "${k}"`) && stringsZh.includes(`"name": "${k}"`),
    `string ${k} in base + zh_CN`);
}

console.log(`D02_ORIGINAL_INDENT_CONTROLS_OK TOTAL=${total} FAILED=${failed}`);
if (failed > 0) {
  process.exit(1);
}
