// D02 原版文本高亮 Replay —— Phase 688
// 证据：原版 cve.java rte 分支 → n(new zyd(..., new eh5(iu1.a, true), ...))
// （点按把当前色板色应用到选区）；同色再点且 isActive → asd.k(null, qse.S)
// 打开取色面板（而非冗余写）；zte.a=OnRemoveHighlight →
// fm7.removeHighlightFromSelection（aj4 op type4 "RemoveHighlight: range"）
// 清除选区高亮 span 后 i(qse.S) 收面板。eh5=HighlightData(color,isActive)。
// Harmony：bindMenu 五色预设 + Remove Highlight → applyHighlightColor 写
// highlightColor 字符 run；清除置 undefined 由 JSON 规范归并剔除；
// 折叠光标走 pendingCharStyles.highlightColor/pendingClearHighlight。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const cve = fs.readFileSync(`${D}/sources/defpackage/cve.java`, 'utf8');
const zyd = fs.readFileSync(`${D}/sources/defpackage/zyd.java`, 'utf8');
const eh5 = fs.readFileSync(`${D}/sources/defpackage/eh5.java`, 'utf8');
const q39 = fs.readFileSync(`${D}/sources/defpackage/q39.java`, 'utf8');
const stringsXml = fs.readFileSync(`${D}/resources/res/values/strings.xml`, 'utf8');
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
check(cve.includes('nueVar.equals(rte.a)') &&
  cve.includes('new eh5(((iu1) ufbVar2.I.getValue()).a, true)'),
  'cve rte: tap applies panel color via eh5{color,true}');
check(cve.includes('!tmf.a(eh5Var.a, ((iu1) ufbVar2.I.getValue()).a)') &&
  cve.includes('asdVar3.k(null, qseVar4)'),
  'cve rte: same-color re-tap opens picker instead of redundant op');
check(cve.includes('nueVar.equals(zte.a)') &&
  cve.includes('"removeHighlightFromSelection"') &&
  cve.includes('i(qse.S)'),
  'cve zte: OnRemoveHighlight clears selection highlight + closes panel');
check(eh5.includes('public final long a') && eh5.includes('public final boolean b') &&
  eh5.includes('HighlightData(color=') && eh5.includes('isActive='),
  'eh5 = HighlightData(color, isActive)');
check(zyd.includes('public final eh5 d'),
  'zyd.d carries the highlight payload');
check(q39.includes('tqe.HIGHLIGHT') && q39.includes('tqe.REMOVE_HIGHLIGHT') &&
  q39.includes('feature_note__selection_menu_remove_highlight'),
  'selection menu maps HIGHLIGHT / REMOVE_HIGHLIGHT');
check(stringsXml.includes('<string name="feature_note__selection_menu_highlight">Highlight</string>') &&
  stringsXml.includes('<string name="feature_note__selection_menu_remove_highlight">Remove Highlight</string>'),
  'original highlight strings');

// ===== Harmony 结构钉 =====
check(model.includes('highlightColor?: number'),
  'RichTextCharacterStyle.highlightColor field exists');
check(renderer.includes('style.highlightColor !== undefined'),
  'renderer paints highlightColor behind text');
check(overlay.includes('private applyHighlightColor(color: number | null, s: number, e: number): void') &&
  overlay.includes('mid.highlightColor = color === null ? undefined : color'),
  'applyHighlightColor writes/clears the run field');
check(overlay.includes('private rangeHasHighlight(s: number, e: number): boolean') &&
  overlay.includes('r.style.highlightColor !== undefined'),
  'selection coverage check for active state');
check(overlay.includes('private toggleHighlightColor(color: number): void') &&
  overlay.includes('this.pendingCharStyles.highlightColor = color'),
  'collapsed caret → pending typing highlight');
check(overlay.includes('private clearHighlight(): void') &&
  overlay.includes('this.applyHighlightColor(null, s, e)'),
  'Remove Highlight clears the selected range');
check(overlay.includes('private pendingClearHighlight: boolean = false') &&
  overlay.includes('this.pendingClearHighlight = true'),
  'collapsed Remove Highlight → pending clear flag');
check(overlay.includes('private buildHighlightMenu(): MenuElement[]') &&
  overlay.includes('this.toggleHighlightColor(1716898048)') &&
  overlay.includes('this.clearHighlight()'),
  'preset-color menu + remove item');
check(overlay.includes("$r('app.string.text_highlight')") &&
  overlay.includes('.bindMenu(this.buildHighlightMenu())') &&
  overlay.includes('@State caretCharHighlight: boolean = false'),
  'Highlight button + bindMenu + active state');
check(overlay.includes('JSON.stringify(r.style) !== \'{}\'') ,
  'normalize drops {highlightColor:undefined} remnants via JSON check');
check(overlay.includes('this.applyHighlightColor(null, editStart, insEnd)') &&
  overlay.includes('this.applyHighlightColor(this.pendingCharStyles.highlightColor,'),
  'pending highlight applied to typed text (set + clear paths)');

// ===== 字符串钉 =====
check(stringsEn.includes('"name": "text_highlight"') &&
  stringsEn.includes('"name": "highlight_remove"') &&
  stringsEn.includes('"name": "highlight_yellow"'),
  'en strings');
check(stringsZh.includes('"name": "text_highlight"') &&
  stringsZh.includes('"value": "高亮"') &&
  stringsZh.includes('"value": "清除高亮"'),
  'zh strings');

console.log(`D02_ORIGINAL_HIGHLIGHT_COLOR_OK TOTAL=${total} FAILED=${failed}`);
if (failed > 0) {
  process.exit(1);
}
