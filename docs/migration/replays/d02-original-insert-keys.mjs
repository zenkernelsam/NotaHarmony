// Phase 1475 — 1.4.2 Ctrl+Shift+M/I 插入和弦（f2:240-247 →
// ea1.p(mc8/nc8) = InsertMath/InsertPhoto）。
// Original evidence (decompiled_1.4.2):
//   pa8.java — D = ofk.e(41) = KEYCODE_M、C = ofk.e(37) = KEYCODE_I。
//   f2.java:240-247（!rsi 门内、!pa8.W 块内、Ctrl+Shift+T 支后、
//     DEL 支前）：
//     `db8.r && db8.s && pa8.a(n, pa8.D)` + UP + `u7b.g`
//       → ea1Var.p(mc8.a) = InsertMath；
//     `db8.r && db8.s && pa8.a(n, pa8.C)` + UP + `u7b.g`
//       → ea1Var.p(nc8.a) = InsertPhoto；
//     支内无 b2=0 → DOWN 亦消费。
//   mc8.java/nc8.java —— tc8 事件单例，toString()=InsertMath/
//     InsertPhoto。
//   u7b.g = ec2.e0 组合旗，默认 Boolean.TRUE（k59.t stylus/hw +
//     yah.m 派生）——键盘组合使能。
// Harmony：onCanvasKeyEvent !textEditing 块内（DPAD nudge 支后、
//   DEL 支前）→ onKeyInsertMath/onKeyInsertPhoto → NotePage 与
//   工具栏 onInsertMath/onInsertPhotos 同管线（mathInsertSignal++ /
//   photoInsertSignal++，同租约门）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const CHORDS = 'note/src/main/ets/data/OriginalKeyboardChords.ets';
const PAGE = 'note/src/main/ets/ui/editor/NotePage.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');
const chords = readFileSync(CHORDS, 'utf8').replace(/\r\n/g, '\n');
const page = readFileSync(PAGE, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 常量：M/I 键码 + 证据注释 ---
check(chords.includes('ORIGIN_KEYCODE_M: number = 2029') &&
  chords.includes('ORIGIN_KEYCODE_I: number = 2025'),
  'Harmony keycodes 2029/2025 pinned (pa8.D=41=M / pa8.C=37=I)');
check(chords.includes('pa8.D = ofk.e(41)') && chords.includes('mc8') &&
  chords.includes('nc8'),
  'constants carry pa8.D/C → mc8/nc8 evidence comment');

// --- 分发支：ctrl+shift 门 + 键码 + UP + 回调 + 消费 ---
const insAnchor = 'Ctrl+Shift+pa8.D(41=M)/pa8.C(37=I)';
const insStart = canvas.indexOf(insAnchor);
check(insStart > 0, 'insert branch annotated with f2 pa8.D/C evidence');
const insBlock = canvas.slice(insStart, insStart + 900);
check(insBlock.includes('ctrl && shift') &&
  insBlock.includes('ORIGIN_KEYCODE_M') && insBlock.includes('ORIGIN_KEYCODE_I'),
  'branch = ctrl&&shift && (M|I) (f2 db8.r&&db8.s)');
check(insBlock.includes('this.onKeyInsertMath()'),
  'Ctrl+Shift+M → onKeyInsertMath (mc8 InsertMath)');
check(insBlock.includes('this.onKeyInsertPhoto()'),
  'Ctrl+Shift+I → onKeyInsertPhoto (nc8 InsertPhoto)');
check(insBlock.includes('return true'),
  'consumes DOWN too (支内无 b2=0)');
// 位置：DEL 支之前（f2 链序 240-246 → 247 DEL）。
const delIdx = canvas.indexOf('pa8.O(67=DEL)/pa8.P(112=FORWARD_DEL)');
check(delIdx > 0 && insStart < delIdx,
  'insert branch precedes DEL branch (f2 chain order 240→247)');
const textEditGate = canvas.indexOf('if (!this.textEditing) {');
check(textEditGate > 0 && textEditGate < insStart,
  'insert branch inside !textEditing block (!rsi gate)');

// --- NotePage 接线：同工具栏管线 + 租约门 ---
const mathIdx = page.indexOf('onKeyInsertMath');
check(mathIdx > 0, 'onKeyInsertPhoto/Math props wired');
check(page.slice(mathIdx - 400, mathIdx + 600)
    .includes('this.mathInsertSignal++'),
  'onKeyInsertMath → mathInsertSignal++ (同工具栏 onInsertMath)');
const photoIdx = page.indexOf('onKeyInsertPhoto: () => void');
const photoBodyIdx = page.indexOf('onKeyInsertPhoto: (): void');
check(photoBodyIdx > 0 &&
  page.slice(photoBodyIdx, photoBodyIdx + 500).includes('this.photoInsertSignal++'),
  'onKeyInsertPhoto → photoInsertSignal++ (同工具栏 onInsertPhotos)');
check(page.slice(photoBodyIdx, photoBodyIdx + 500)
    .includes('this.photoImportLeaseActive = true'),
  'photo insert takes ingress lease (同 onInsertPhotos)');

// --- 可执行模型：f2 门控 ---
function insertKey(ctrl, shift, code, action) {
  // f2: r&&s && (D|M=41 / C|I=37) → UP 触发、命中即消费
  if (!ctrl || !shift || (code !== 'M' && code !== 'I')) {
    return 'pass-through';
  }
  if (action !== 'UP') return 'consumed-noop';
  return code === 'M' ? 'insert-math' : 'insert-photo';
}
check(insertKey(true, true, 'M', 'UP') === 'insert-math',
  'model: Ctrl+Shift+M UP → InsertMath');
check(insertKey(true, true, 'I', 'UP') === 'insert-photo',
  'model: Ctrl+Shift+I UP → InsertPhoto');
check(insertKey(true, true, 'M', 'DOWN') === 'consumed-noop',
  'model: DOWN consumed, no action');
check(insertKey(true, false, 'M', 'UP') === 'pass-through',
  'model: Ctrl+M no shift → not this branch');
check(insertKey(false, true, 'M', 'UP') === 'pass-through',
  'model: Shift+M no ctrl → not this branch');
check(insertKey(true, true, 'X', 'UP') === 'pass-through',
  'model: other key → pass-through');

console.log(`d02-original-insert-keys: ${n} checks OK`);
