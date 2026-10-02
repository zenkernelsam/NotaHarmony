// Phase 1472 — 1.4.2 Ctrl+D 复制选区（f2 兜底链 → xc8 byte1 →
// ot2.a(msf) = Duplicate）。
// Original evidence (decompiled_1.4.2):
//   pa8.java — pa8.y = ofk.e(32) = KEYCODE_D。
//   f2.java:219-227 — !pa8.W(279) 块内、!rsi 门内兜底链：
//     `if (db8.r(e)) { if (pa8.a(n, y) && lxm.a(o,1) &&
//       (msf = d63.f.F.getValue()) != null)
//       tee.I(z(), new xc8(bd8, msf, null, b2=1)); }`
//     —— 只查 db8.r(Ctrl)，无 db8.q(Alt)/db8.s(Shift) 排他门；
//     DOWN 与无选区支内无 b2=0 回落 → 消费不动作；无选区 UP
//     走同支 else 推 qc8.a 单例空事件（仍消费）。
//   xc8.java — byte=1 → ot2.a(msf)（byte=0 为 Ctrl+X → ot2.e cut）。
//   ot2.a —— lt2 负载构建 → ome.a() 清原选 → f(jt2, 选区中心 +
//     min((sbe.c-sbe.a)*0.1, 30) 双轴等值偏移) 粘贴副本（f2:333-345
//     内联同款偏移式亦可佐证）。
// Harmony：onCanvasKeyEvent !textEditing 块内增 Ctrl+D 支，复用
//   SelectionMenuAction.DUPLICATE → duplicateSelected 管线
//   （copySelectedToClipboard + selectionPasteTarget +
//   min(rectWidthCanvas*0.1, 30) 双轴偏移 + pasteClipboard）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const CHORDS = 'note/src/main/ets/data/OriginalKeyboardChords.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');
const chords = readFileSync(CHORDS, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 常量：D 键码 + 原版证据注释 ---
check(chords.includes('ORIGIN_KEYCODE_D: number = 2020'),
  'Harmony keycode 2020 pinned (pa8.y = ofk.e(32) = KEYCODE_D)');
check(chords.includes('pa8.y = ofk.e(32)') && chords.includes('xc8'),
  'constant carries original pa8.y → xc8 evidence comment');

// --- 分发支：Ctrl 门 + 键码 + UP+选区门 + DUPLICATE 管线 ---
const dupAnchor = 'Ctrl+pa8.y(32=D)';
const dupStart = canvas.indexOf(dupAnchor);
check(dupStart > 0, 'dispatch branch annotated with f2 pa8.y evidence');
const dupBlock = canvas.slice(dupStart, dupStart + 700);
check(dupBlock.includes('ctrl && event.keyCode === ORIGIN_KEYCODE_D'),
  'branch requires Ctrl (db8.r) + KEYCODE_D');
check(dupBlock.includes('isUp && this.selectionTool.getState().isActive'),
  'key-UP + selection active gate (lxm.a(o,1) && msf != null)');
check(dupBlock.includes('this.onSelectionMenuAction(SelectionMenuAction.DUPLICATE)'),
  'fires menu DUPLICATE pipeline (xc8 byte1 → ot2.a)');
check(dupBlock.includes('return true'),
  'consumes DOWN/no-selection too (f2 支内无 b2=0 → qc8 空事件仍消费)');
// 无 Shift/Alt 排他门：条件不得含 !shift/!keyChordAlt。
const dupCond = dupBlock.slice(dupBlock.indexOf('if (ctrl'),
  dupBlock.indexOf('if (ctrl') + 90);
check(!dupCond.includes('shift') && !dupCond.includes('keyChordAlt'),
  'no Shift/Alt exclusion (f2 只查 db8.r，无 !db8.s/!db8.q)');

// --- 位置：在 !textEditing 块内、digit 工具选择支之前 ---
const digitIdx = canvas.indexOf('toolSelectDigitIndex(event)');
check(digitIdx > 0 && dupStart < digitIdx,
  'Ctrl+D branch precedes digit tool-select in fallback chain');
const textEditGate = canvas.indexOf('if (!this.textEditing) {');
check(textEditGate > 0 && textEditGate < dupStart,
  'duplicate branch inside !textEditing block (Q.m instanceof rsi gate)');

// --- DUPLICATE 管线等价性 pin ---
const dupFn = canvas.slice(canvas.indexOf('private duplicateSelected('),
  canvas.indexOf('private duplicateSelected(') + 1600);
check(dupFn.includes('copySelectedToClipboard('),
  'duplicate builds clipboard payload (ot2.a: lt2 负载构建)');
check(dupFn.includes('this.selectionPasteTarget()'),
  'duplicate targets selection center (ot2.a: jt2 选区中心)');
check(dupFn.includes('Math.min(rectWidthCanvas * 0.1, 30)'),
  'offset = min(width*0.1, 30) page units (ot2.a/f2:341 同款式)');
check(dupFn.includes('duplicateTarget: Point2D = { x: target.x + nudge, y: target.y + nudge }'),
  'equal x/y nudge (f2 s64.a(fMin,fMin) 双轴同值)');
check(dupFn.includes('this.pasteClipboard(duplicateTarget)'),
  'paste at offset target (ot2.a: f() 偏移粘贴)');
check(canvas.indexOf('action === SelectionMenuAction.DUPLICATE') > 0 &&
  canvas.slice(canvas.indexOf('action === SelectionMenuAction.DUPLICATE'),
    canvas.indexOf('action === SelectionMenuAction.DUPLICATE') + 400)
    .includes('this.duplicateSelected('),
  'menu DUPLICATE routes to duplicateSelected (keyboard/menu 同核)');

// --- 可执行模型：f2 分支门控 + 偏移语义 ---
function ctrlD(ctrlHeld, action, hasSelection) {
  // f2: db8.r&&pa8.a(n,y) 支；支内无 b2=0 → 匹配即消费。
  if (!ctrlHeld) return 'pass-through'; // 未到本支
  if (action === 'UP' && hasSelection) return 'duplicated';
  return 'consumed-noop'; // DOWN 或无选区 → qc8 空事件
}
check(ctrlD(true, 'UP', true) === 'duplicated',
  'model: Ctrl+D UP + selection → duplicate');
check(ctrlD(true, 'DOWN', true) === 'consumed-noop',
  'model: Ctrl+D DOWN consumed, no action');
check(ctrlD(true, 'UP', false) === 'consumed-noop',
  'model: Ctrl+D UP no selection → qc8 no-op, still consumed');
check(ctrlD(false, 'UP', true) === 'pass-through',
  'model: no Ctrl → branch not entered');

function dupTarget(center, widthPage) {
  // ot2.a / f2:341: offset = min(w*0.1, 30), equal on x/y
  const nudge = widthPage > 0 ? Math.min(widthPage * 0.1, 30) : 30;
  return { x: center.x + nudge, y: center.y + nudge };
}
const t1 = dupTarget({ x: 100, y: 200 }, 200);
check(t1.x === 120 && t1.y === 220,
  'model: w=200 → nudge 20 on both axes');
const t2 = dupTarget({ x: 100, y: 200 }, 1000);
check(t2.x === 130 && t2.y === 230,
  'model: w=1000 → clamped to 30 on both axes');
const t3 = dupTarget({ x: 50, y: 60 }, 0);
check(t3.x === 80 && t3.y === 90,
  'model: non-finite/zero width → 30 fallback nudge');

console.log(`d02-original-selection-duplicate-key: ${n} checks OK`);
