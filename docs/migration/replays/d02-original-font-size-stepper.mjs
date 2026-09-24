// Phase 694 — 原版字号步进（kre FontSizeTextToolbarItem / pte -> cve.l(f)
// -> zyd.f clamp [4,72]）移植静态 Replay。
// 证据：decompiled_1.0.3 sources/defpackage/{cve,kre,ave,pte,i31,ure}.java
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

let total = 0;
const check = (cond, label) => { total++; assert.ok(cond, label); };
const read = (p) => readFileSync(p, 'utf8');
const SRC = process.env.NOTA_SRC ?? 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';

// ---------- 原版证据钉 ----------
const cve = read(`${SRC}/sources/defpackage/cve.java`);
check(cve.includes('nueVar instanceof pte') &&
  cve.includes('l(((pte) nueVar).a)'),
  'cve: pte -> l(float)');
check(cve.includes('rh8.u(f, 4.0f, 72.0f)') &&
  cve.includes('Float.valueOf(rh8.u(f, 4.0f, 72.0f))'),
  'cve.l: zyd.f = clamp(f, 4, 72)');

const kre = read(`${SRC}/sources/defpackage/kre.java`);
check(kre.includes('FontSizeTextToolbarItem(size=') &&
  kre.includes('onIncreaseSizeClick=') && kre.includes('onDecreaseSizeClick='),
  'kre = FontSizeTextToolbarItem{size,onClick,onIncrease,onDecrease}');

const ave = read(`${SRC}/sources/defpackage/ave.java`);
check(ave.includes('cveVar2.l(f2 + 1.0f)') && ave.includes('cveVar2.l(f2 - 1.0f)'),
  'ave: increase/decrease steps ±1.0pt');

const i31 = read(`${SRC}/sources/defpackage/i31.java`);
check(i31.includes('new pte(((Float) obj).floatValue())'),
  'i31 case 20: emits pte(float)');

const ure = read(`${SRC}/sources/defpackage/ure.java`);
check(ure.includes('fontSizeState='), 'ure TextToolbarState carries fontSizeState');

// ---------- Harmony 实现钉 ----------
const overlay = read('note/src/main/ets/ui/components/TextBlockOverlay.ets');
check(overlay.includes('@State caretCharFontSize: number'),
  'overlay: caretCharFontSize state');
check(overlay.includes('private stepFontSize(delta: number): void'),
  'overlay: stepFontSize helper');
check(overlay.includes('Math.max(4, Math.min(72, current + delta))'),
  'overlay: ±1pt step clamped [4,72] = rh8.u(f,4,72)');
check(overlay.includes('private fontSizeAt(s: number, e: number): number'),
  'overlay: fontSizeAt — selection size source');
check(overlay.includes('private fontSizeNearCaret(): number | undefined'),
  'overlay: fontSizeNearCaret — folded-caret run source');
check(overlay.includes('this.pendingCharStyles.fontSize = next'),
  'overlay: folded caret writes pending typing-attributes');
check(overlay.includes('this.applyFontSize(next, s, e)') &&
  overlay.includes('this.normalizeCharRuns()'),
  'overlay: selection writes fontSize run + normalize');
check(overlay.includes('this.stepFontSize(-1)') &&
  overlay.includes('this.stepFontSize(1)'),
  'overlay: − / + steppers wired');
check(overlay.includes('`${this.caretCharFontSize}`'),
  'overlay: current size displayed (kre.a equivalent)');

// 步骤钮在原版字体格式簇内（Style→Size→Family）
const styleIdx = overlay.indexOf("$r('app.string.text_style')");
const minusIdx = overlay.indexOf("this.stepFontSize(-1)");
const familyIdx = overlay.indexOf("$r('app.string.font_family')");
check(styleIdx > 0 && minusIdx > styleIdx && familyIdx > minusIdx,
  'overlay: stepper between Style and Font buttons (original q->r->s order)');

console.log(`D02_ORIGINAL_FONT_SIZE_STEPPER_REPLAY_OK TOTAL=${total} FAILED=0`);
