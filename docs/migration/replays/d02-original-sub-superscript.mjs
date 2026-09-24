// D02 原版上下标互斥切换 Replay —— Phase 685
// 证据：原版 cve.java kue(superscript)/lue(subscript) 分支向 zyd 同包写
// 显式互斥——启用时 field=TRUE + 兄弟=FALSE（mask 1279），停用时只写
// 本字段 FALSE（mask 1535/1791）；zyd.i=subscript、zyd.j=superscript。
// l32 case4/5 渲染 subscript/superscript 行（行序 italic/underline/
// subscript/superscript/strikethrough）。Harmony：toggleCharStylePair
// 复刻同包互斥语义；pending 落地按"显式存在"应用含 FALSE 清除。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const cve = fs.readFileSync(`${D}/sources/defpackage/cve.java`, 'utf8');
const l32 = fs.readFileSync(`${D}/sources/defpackage/l32.java`, 'utf8');
const zyd = fs.readFileSync(`${D}/sources/defpackage/zyd.java`, 'utf8');
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
check(cve.includes('nueVar.equals(kue.a)') &&
  cve.includes('Boolean.FALSE, Boolean.TRUE, null, 1279') &&
  cve.includes('null, Boolean.FALSE, null, 1535'),
  'cve: kue → zyd j=TRUE+i=FALSE enable / j=FALSE disable (superscript)');
check(cve.includes('nueVar.equals(lue.a)') &&
  cve.includes('Boolean.TRUE, Boolean.FALSE, null, 1279') &&
  cve.includes('Boolean.FALSE, null, null, 1791'),
  'cve: lue → zyd i=TRUE+j=FALSE enable / i=FALSE disable (subscript)');
check(cve.includes('!((br2) ufbVar.I.getValue()).f') &&
  cve.includes('!((br2) ufbVar.I.getValue()).e'),
  'cve: br2.f=superscript / br2.e=subscript state read');
check(zyd.includes('public final Boolean i;') &&
  zyd.includes('public final Boolean j;'),
  'zyd payload fields i/j');
check(l32.includes('R.string.ui_text__subscript') &&
  l32.includes('R.string.ui_text__superscript'),
  'l32 renders subscript/superscript rows');
check(l32.indexOf('R.string.ui_text__subscript') <
  l32.indexOf('R.string.ui_text__superscript') &&
  l32.indexOf('R.string.ui_text__superscript') <
  l32.indexOf('R.string.ui_text__strikethrough'),
  'l32 row order: sub < super < strikethrough');
check(stringsXml.includes('<string name="ui_text__subscript">Subscript</string>') &&
  stringsXml.includes('<string name="ui_text__superscript">Superscript</string>'),
  'original sub/superscript strings');

// ===== Overlay 字段与互斥语义钉 =====
check(overlay.includes("if (field === 'subscript') { return style.subscript === true; }") &&
  overlay.includes("if (field === 'superscript') { return style.superscript === true; }") &&
  overlay.includes("else if (field === 'subscript') { style.subscript = value; }") &&
  overlay.includes("else if (field === 'superscript') { style.superscript = value; }"),
  'charStyleValue/charStyleSet sub+super cases');
check(overlay.includes('private charStyleHas(style: RichTextCharacterStyle, field: string): boolean') &&
  overlay.includes("if (field === 'subscript') { return style.subscript !== undefined; }") &&
  overlay.includes("if (field === 'superscript') { return style.superscript !== undefined; }"),
  'charStyleHas explicit-presence check (false≠unset)');
check(overlay.includes('private toggleCharStylePair(field: string, other: string): void') &&
  overlay.includes('this.charStyleSet(this.pendingCharStyles, other, false)') &&
  overlay.includes('this.applyCharStyle(other, false, s, e)'),
  'exclusive pair: enable writes sibling explicit FALSE (zyd 1279 语义)');
check(overlay.includes('if (this.charStyleValue(this.pendingCharStyles, field)) {') &&
  overlay.includes('this.charStyleSet(this.pendingCharStyles, field, false);'),
  'pair disable writes only own FALSE (zyd 1535/1791 语义)');
check(overlay.includes('@State caretCharSub: boolean = false') &&
  overlay.includes('@State caretCharSuper: boolean = false') &&
  overlay.includes("this.caretCharSub = this.rangeHasCharStyle('subscript', s, e)") &&
  overlay.includes("this.caretCharSuper = this.rangeHasCharStyle('superscript', s, e)"),
  'sub/super button states');

// ===== pending 落地钉：显式存在字段按值应用（false 清兄弟） =====
check(overlay.includes('this.charStyleHas(this.pendingCharStyles, field)') &&
  overlay.includes('this.charStyleValue(this.pendingCharStyles, field),\n                      editStart, insEnd'),
  'pending apply uses explicit presence (clears sibling on typed text)');
check(overlay.includes("'subscript', 'superscript'"),
  'pending apply field list covers sub/super');

// ===== 工具条钉（l32 行序：underline → sub → super → strikethrough） =====
check(overlay.includes("Button($r('app.string.subscript'))") &&
  overlay.includes("Button($r('app.string.superscript'))") &&
  overlay.includes("this.toggleCharStylePair('subscript', 'superscript')") &&
  overlay.includes("this.toggleCharStylePair('superscript', 'subscript')"),
  'sub/super buttons wired to exclusive toggle');
check(overlay.indexOf("app.string.underline')") <
  overlay.indexOf("app.string.subscript')") &&
  overlay.indexOf("app.string.subscript')") <
  overlay.indexOf("app.string.superscript')") &&
  overlay.indexOf("app.string.superscript')") <
  overlay.indexOf("app.string.strikethrough')"),
  'button order matches l32: underline < sub < super < strikethrough');

// ===== 渲染器与字符串钉 =====
check(renderer.includes('style.superscript === true') &&
  renderer.includes('style.subscript === true') &&
  renderer.includes('base * 0.75'),
  'renderer shifts baseline + scales font for super/sub');
for (const k of ['subscript', 'superscript']) {
  check(stringsEn.includes(`"name": "${k}"`) && stringsZh.includes(`"name": "${k}"`),
    `string ${k} in base + zh_CN`);
}

console.log(`D02_ORIGINAL_SUB_SUPERSCRIPT_OK TOTAL=${total} FAILED=${failed}`);
if (failed > 0) {
  process.exit(1);
}
