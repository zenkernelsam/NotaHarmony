// Phase 693 — 原版段落对齐（vse/i5a/r4a）+ 行距（wte/j5a/fg7）移植静态 Replay。
// 证据：decompiled_1.0.3 sources/defpackage/{cve,i5a,j5a,r4a,fg7,ure,oue,i31,hse,pre}.java
import { readFileSync, existsSync } from 'node:fs';
import { strict as assert } from 'node:assert';

let total = 0;
const check = (cond, label) => { total++; assert.ok(cond, label); };
const read = (p) => readFileSync(p, 'utf8');
const SRC = process.env.NOTA_SRC ?? 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';

// ---------- 原版证据钉 ----------
const cve = read(`${SRC}/sources/defpackage/cve.java`);
check(cve.includes('nueVar instanceof vse') &&
  cve.includes('m(new i5a(((vse) nueVar).a))'),
  'cve: vse -> m(i5a(SetAlignment))');
check(cve.includes('nueVar instanceof wte') &&
  cve.includes('m(new j5a(((wte) nueVar).a))'),
  'cve: wte -> m(j5a(SetLineSpacing))');
check(cve.includes('nueVar.equals(iue.a)') && cve.includes('qse.P'),
  'cve: iue opens qse.P alignment panel');
check(cve.includes('nueVar.equals(gue.a)') && cve.includes('qse.Q'),
  'cve: gue opens qse.Q line-spacing panel');

const i5a = read(`${SRC}/sources/defpackage/i5a.java`);
check(i5a.includes('SetAlignment(alignment='), 'i5a = SetAlignment op');
const j5a = read(`${SRC}/sources/defpackage/j5a.java`);
check(j5a.includes('SetLineSpacing(spacing='), 'j5a = SetLineSpacing op');

const r4a = read(`${SRC}/sources/defpackage/r4a.java`);
check(r4a.includes('LEFT((byte) 1)') && r4a.includes('CENTER((byte) 2)') &&
  r4a.includes('RIGHT((byte) 3)'), 'r4a = LEFT/CENTER/RIGHT = 1/2/3');

const fg7 = read(`${SRC}/sources/defpackage/fg7.java`);
check(fg7.includes('Float.valueOf(1.0f), Float.valueOf(1.5f), Float.valueOf(2.0f)'),
  'fg7: availableSpacings = [1.0, 1.5, 2.0]');
check(fg7.includes('LineSpacingPopoverState(currentSpacing='),
  'fg7 = LineSpacingPopoverState');

const ure = read(`${SRC}/sources/defpackage/ure.java`);
check(ure.includes('alignmentState=') && ure.includes('lineSpacingState='),
  'ure TextToolbarState carries alignment + lineSpacing states');

const oue = read(`${SRC}/sources/defpackage/oue.java`);
check(oue.includes('new vse(r4a.LEFT)') && oue.includes('new vse(r4a.CENTER)') &&
  oue.includes('new vse(r4a.RIGHT)'),
  'oue: toolbar cases emit vse(LEFT/CENTER/RIGHT)');

const stringsXml = read(`${SRC}/resources/res/values/strings.xml`);
check(stringsXml.includes('ui_text__align_left">Align left') &&
  stringsXml.includes('ui_text__align_center">Align center') &&
  stringsXml.includes('ui_text__align_right">Align right') &&
  stringsXml.includes('ui_text__line_spacing">Line spacing') &&
  stringsXml.includes('ui_text__text_alignment">Text alignment'),
  'original strings: alignment + line spacing labels');

// ---------- Harmony 实现钉 ----------
const overlay = read('note/src/main/ets/ui/components/TextBlockOverlay.ets');
check(overlay.includes('private setAlignment(value: number): void'),
  'overlay: setAlignment helper');
check(overlay.includes('next.alignment = value'),
  'overlay: setAlignment writes alignment field');
check(overlay.includes('private setLineSpacing(value: number): void'),
  'overlay: setLineSpacing helper');
check(overlay.includes('next.lineSpacing = value'),
  'overlay: setLineSpacing writes lineSpacing field');
check(overlay.includes('private refreshCaretParagraphExtras(): void') &&
  overlay.includes('this.caretAlignment = current.alignment ?? 1') &&
  overlay.includes('this.caretLineSpacing = current.lineSpacing ?? 1'),
  'overlay: caret tracking for alignment + lineSpacing');
check(overlay.includes("app.string.align_left") &&
  overlay.includes('this.setAlignment(1)') &&
  overlay.includes('this.setAlignment(2)') &&
  overlay.includes('this.setAlignment(3)'),
  'overlay: alignment menu emits 1/2/3 = LEFT/CENTER/RIGHT');
check(overlay.includes('const values: number[] = [1.0, 1.5, 2.0]') &&
  overlay.includes('this.setLineSpacing(spacing)'),
  'overlay: spacing menu offers fg7 {1.0,1.5,2.0}');
check(overlay.includes('.bindMenu(this.buildAlignmentMenu())') &&
  overlay.includes('.bindMenu(this.buildLineSpacingMenu())'),
  'overlay: two bindMenu buttons wired');
check(overlay.includes("$r('app.string.text_alignment')") &&
  overlay.includes("$r('app.string.line_spacing')"),
  'overlay: button labels localized');

const en = read('note/src/main/resources/base/element/string.json');
const zh = read('note/src/main/resources/zh_CN/element/string.json');
for (const key of ['text_alignment', 'align_left', 'align_center', 'align_right', 'line_spacing']) {
  check(en.includes(`"name": "${key}"`), `en string: ${key}`);
}
check(zh.includes('"文本对齐"') && zh.includes('"左对齐"') &&
  zh.includes('"居中对齐"') && zh.includes('"右对齐"') && zh.includes('"行距"'),
  'zh strings localized');

// 渲染层既有字段兑现（模型+renderer 早于本 Phase 就位）
const model = read('note/src/main/ets/core/model/ElementTypes.ets');
check(model.includes('alignment?: number') && model.includes('lineSpacing?: number'),
  'model: RichTextParagraphStyle carries alignment + lineSpacing');
const renderer = read('note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets');
check(renderer.includes('paragraph.alignment === 2') &&
  renderer.includes('paragraph.alignment === 3') &&
  renderer.includes('paragraph.lineSpacing'),
  'renderer: alignment 2/3 + lineSpacing honored');

console.log(`D02_ORIGINAL_PARAGRAPH_FORMAT_REPLAY_OK TOTAL=${total} FAILED=0`);
