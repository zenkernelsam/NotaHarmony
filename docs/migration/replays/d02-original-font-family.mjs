// D02 原版字体族 Replay —— Phase 691
// 证据：原版 i31 字体族项 → ix4Var.invoke(new nte(zq8Var))；
// cve nte 分支 → n(new zyd(..., ((nte) nueVar).a.a, ..., 2031))
// （arg5=zq8.a modelName → familyName）；qr4.c/d 三随包字体
// Inter(=b 缺省)/Roboto/EBGaramond（zq8{a=modelName,b=displayName,
// c=fontFamily}），qr4.g 六下载字体为服务端资源不在移植范围。
// Harmony：Font 钮 bindMenu 三族 + Default → applyFontFamily 写/清
// familyName run；折叠光标 pending.familyName/pendingClearFamily。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const cve = fs.readFileSync(`${D}/sources/defpackage/cve.java`, 'utf8');
const zyd = fs.readFileSync(`${D}/sources/defpackage/zyd.java`, 'utf8');
const qr4 = fs.readFileSync(`${D}/sources/defpackage/qr4.java`, 'utf8');
const zq8 = fs.readFileSync(`${D}/sources/defpackage/zq8.java`, 'utf8');
const i31 = fs.readFileSync(`${D}/sources/defpackage/i31.java`, 'utf8');
const overlay = fs.readFileSync(
  'note/src/main/ets/ui/components/TextBlockOverlay.ets', 'utf8').replaceAll('\r\n', '\n');
const model = fs.readFileSync(
  'note/src/main/ets/core/model/ElementTypes.ets', 'utf8').replaceAll('\r\n', '\n');
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
check(cve.includes('nueVar instanceof nte') &&
  cve.includes('((nte) nueVar).a.a') &&
  cve.includes('2031));'),
  'cve nte: family pick → zyd.e=zq8.a mask2031 + close qse.N');
check(i31.includes('ix4Var.invoke(new nte(zq8Var))'),
  'i31 family item → nte(zq8)');
check(zq8.includes('public final String a') &&
  zq8.includes('NbFont(modelName=') &&
  zq8.includes('displayName='),
  'zq8 = NbFont{modelName,displayName,fontFamily}');
check(qr4.includes('new zq8("Inter", "Inter"') &&
  qr4.includes('new zq8("Roboto", "Roboto"') &&
  qr4.includes('new zq8("EBGaramond", "EB Garamond"') &&
  qr4.includes('b = zq8Var'),
  'qr4.c/d: Inter/Roboto/EBGaramond, Inter is default b');
check(qr4.includes('"NotoSerif"') && qr4.includes('"DancingScript"'),
  'qr4.g downloadable fonts map (out of scope)');
check(zyd.includes('public final String e'),
  'zyd.e = familyName payload slot');

// ===== Harmony 结构钉 =====
check(model.includes('familyName?: string'),
  'RichTextCharacterStyle.familyName field exists');
check(renderer.includes('style.familyName === undefined') &&
  renderer.includes('style.familyName.replaceAll'),
  'renderer builds font token from familyName');
check(overlay.includes('private applyFontFamily(name: string | null, s: number, e: number): void') &&
  overlay.includes('mid.familyName = name === null ? undefined : name;') &&
  overlay.includes('style: { familyName: name }'),
  'applyFontFamily writes/clears the run field');
check(overlay.includes('private pickFontFamily(name: string): void') &&
  overlay.includes('this.pendingCharStyles.familyName = name'),
  'pickFontFamily: selection write / collapsed pending');
check(overlay.includes('private clearFontFamily(): void') &&
  overlay.includes('this.applyFontFamily(null, s, e)') &&
  overlay.includes('this.pendingClearFamily = true'),
  'Default: clear run field / pending clear flag');
check(overlay.includes('private buildFontMenu(): MenuElement[]') &&
  overlay.includes("this.pickFontFamily('Inter')") &&
  overlay.includes("this.pickFontFamily('Roboto')") &&
  overlay.includes("this.pickFontFamily('EBGaramond')") &&
  overlay.includes('this.clearFontFamily()'),
  'menu mirrors qr4 families + Default');
check(overlay.includes("$r('app.string.font_family')") &&
  overlay.includes('.bindMenu(this.buildFontMenu())') &&
  overlay.indexOf("$r('app.string.font_family')") >
    overlay.indexOf("$r('app.string.text_style')") &&
  overlay.indexOf("$r('app.string.font_family')") <
    overlay.indexOf("$r('app.string.bold')"),
  'Font button between Style and Bold');
check(overlay.includes('this.applyFontFamily(null, editStart, insEnd)') &&
  overlay.includes('this.applyFontFamily(this.pendingCharStyles.familyName,'),
  'pending family applied to typed text (set + clear paths)');

// ===== 字符串钉 =====
check(stringsEn.includes('"name": "font_family"') &&
  stringsEn.includes('"name": "font_default"'),
  'en strings');
check(stringsZh.includes('"name": "font_family"') &&
  stringsZh.includes('"value": "字体"') &&
  stringsZh.includes('"value": "默认"'),
  'zh strings');

console.log(`D02_ORIGINAL_FONT_FAMILY_OK TOTAL=${total} FAILED=${failed}`);
if (failed > 0) {
  process.exit(1);
}
