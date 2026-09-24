// D02 原版文字颜色 Replay —— Phase 690
// 证据：原版 cve.java qte 分支 → this.Y 色井态更新 + n(new zyd(...,
// new iu1(j), ..., 1983))（arg7=foregroundColor）；ste 分支 → e.f(ste.a)
// 直接写选区；hue→qse.O 打开文字色面板（i31 色井区）。zyd.g=iu1 即
// RichTextCharacterStyle.foregroundColor；字段缺省 = element.fontColor。
// Harmony：TEXT_COLOR_PRESETS 12 色 sheet（ColorPickerView.presetColors
// 同源）→ applyForegroundColor 写/清 run；折叠光标 pending.foregroundColor
// /pendingClearForeground；Automatic=字段清除。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const cve = fs.readFileSync(`${D}/sources/defpackage/cve.java`, 'utf8');
const zyd = fs.readFileSync(`${D}/sources/defpackage/zyd.java`, 'utf8');
const i31 = fs.readFileSync(`${D}/sources/defpackage/i31.java`, 'utf8');
const overlay = fs.readFileSync(
  'note/src/main/ets/ui/components/TextBlockOverlay.ets', 'utf8').replaceAll('\r\n', '\n');
const model = fs.readFileSync(
  'note/src/main/ets/core/model/ElementTypes.ets', 'utf8').replaceAll('\r\n', '\n');
const renderer = fs.readFileSync(
  'note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets', 'utf8').replaceAll('\r\n', '\n');
const picker = fs.readFileSync(
  'note/src/main/ets/ui/components/ColorPicker.ets', 'utf8').replaceAll('\r\n', '\n');
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
check(cve.includes('nueVar instanceof qte') &&
  cve.includes('new iu1(j)') &&
  cve.includes('1983));'),
  'cve qte: picked color → zyd.g=iu1 mask1983 + well state');
check(cve.includes('nueVar instanceof ste') &&
  cve.includes('j().e.f(((ste) nueVar).a)'),
  'cve ste: apply color to selection via fm7.e.f');
check(cve.includes('nueVar.equals(hue.a)') && cve.includes('qse qseVar6 = qse.O'),
  'cve hue: opens qse.O text-color panel');
check(zyd.includes('public final iu1 g'),
  'zyd.g = iu1 foreground color payload');
check(i31.includes('ix4Var.invoke(new nte(zq8Var))'),
  'i31 font panel also hosts family picker (P691 scope)');

// ===== Harmony 结构钉 =====
check(model.includes('foregroundColor?: number'),
  'RichTextCharacterStyle.foregroundColor field exists');
check(renderer.includes('style.foregroundColor ?? element.fontColor'),
  'renderer fills text with foregroundColor fallback element.fontColor');
check(overlay.includes('const TEXT_COLOR_PRESETS: number[] = [') &&
  overlay.includes('-16777216') && overlay.includes('-16776961') &&
  overlay.includes('-1,'),
  'TEXT_COLOR_PRESETS palette present');
check(picker.includes('-16777216') && picker.includes('-10011977'),
  'palette shares ColorPickerView preset source');
check(overlay.includes('private applyForegroundColor(color: number | null, s: number, e: number): void') &&
  overlay.includes('mid.foregroundColor = color === null ? undefined : color;') &&
  overlay.includes('style: { foregroundColor: color }'),
  'applyForegroundColor writes/clears the run field');
check(overlay.includes('private pickTextColor(color: number): void') &&
  overlay.includes('this.pendingCharStyles.foregroundColor = color'),
  'pickTextColor: selection write / collapsed pending');
check(overlay.includes('private clearTextColor(): void') &&
  overlay.includes('this.applyForegroundColor(null, s, e)') &&
  overlay.includes('this.pendingClearForeground = true'),
  'Automatic: clear run field / pending clear flag');
check(overlay.includes('@State showTextColorSheet: boolean = false') &&
  overlay.includes('private buildTextColorSheet(): void') &&
  overlay.includes('ForEach(TEXT_COLOR_PRESETS') &&
  overlay.includes('SheetSize.MEDIUM'),
  'bindSheet palette grid');
check(overlay.includes("$r('app.string.text_color')") &&
  overlay.includes('this.applyForegroundColor(this.pendingCharStyles.foregroundColor,') &&
  overlay.includes('this.applyForegroundColor(null, editStart, insEnd)'),
  'Color button + pending apply both paths');

// ===== 字符串钉 =====
check(stringsEn.includes('"name": "text_color"') &&
  stringsEn.includes('"name": "color_automatic"'),
  'en strings');
check(stringsZh.includes('"name": "text_color"') &&
  stringsZh.includes('"value": "颜色"') &&
  stringsZh.includes('"value": "自动"'),
  'zh strings');

console.log(`D02_ORIGINAL_TEXT_COLOR_OK TOTAL=${total} FAILED=${failed}`);
if (failed > 0) {
  process.exit(1);
}
