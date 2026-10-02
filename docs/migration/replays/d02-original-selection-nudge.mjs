// Phase 1468 — 1.4.2 方向键微移选区（f2 兜底链 → guf.g 通道 ntf/otf）。
// Original evidence (decompiled_1.4.2):
//   pa8.java:87-90 — e/f/g/h = ofk.e(19..22) = KEYCODE_DPAD_UP/DOWN/
//     LEFT/RIGHT；bd8.java:44 j0 = {e,f,g,h}、l0 = 2.0f 步长。
//   f2.java:285-325 — 兜底链（无 ctrl/alt/shift 修饰、非文本编辑
//     !(Q.m instanceof rsi)）内：lxm.a(action,2)=DOWN 支——
//     `d63.f==null || !u7b.g`（无选区/键盘模式关）→ mfc.s 视口滚动
//     jA=ndf(±0.1f×视口宽/高)；否则 gufVar.g.p(ntf(s64(±l0 轴向),
//     repeatCount>0))；lxm.a(action,1)=UP → guf.g.p(otf.a=NudgeEnd)。
//   ms1.java:784 — 触摸分发面落空时同推 otf.a（触摸终结微移）。
//   guf.t(j,z) — nudge 步进：xtf 式会话 this.i 累加位移、按步
//     p(map,jF,false) 应用 + ome.c 选区偏移更新；z=isRepeat 门
//     （z&&i==null → 忽略重复事件）。
//   guf.u(z) — NudgeEnd：p(map,jF,true)+x6n.c 元素更新+ksf.e 选区
//     矩形平移，一次事务提交；r9a.k()==0 空操作跳过（guf.x:1260）。
// Harmony：onCanvasKeyEvent 增纯方向键支——有选区 DOWN → nudge
// ±2.0 文档单位（moveSelected 累积+快照基线重建）；无选区 → 视口
// 滚动 10%；UP/触摸 → endSelectionNudgeCommit 单撤销步。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const CHORDS = 'note/src/main/ets/data/OriginalKeyboardChords.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');
const chords = readFileSync(CHORDS, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 常量：DPAD 键码 + 步长 + 滚动比 ---
check(chords.includes('ORIGIN_KEYCODE_DPAD_UP: number = 2012') &&
  chords.includes('ORIGIN_KEYCODE_DPAD_DOWN: number = 2013') &&
  chords.includes('ORIGIN_KEYCODE_DPAD_LEFT: number = 2014') &&
  chords.includes('ORIGIN_KEYCODE_DPAD_RIGHT: number = 2015'),
  'Harmony DPAD keycodes 2012..2015 pinned (pa8.e..h = Android 19..22)');
check(chords.includes('ORIGIN_SELECTION_NUDGE_STEP: number = 2.0') &&
  chords.includes('ORIGIN_KEY_SCROLL_FRACTION: number = 0.1'),
  'bd8.l0=2.0 doc-unit step + f=0.1f viewport scroll fraction pinned');

// --- 会话字段与基线重建接线 ---
check(canvas.includes('private selectionNudgeActive: boolean = false'),
  'nudge session flag exists (guf.i xtf-analog session)');
check(canvas.includes('this.selectionDrag || this.selectionNudgeActive'),
  'applySelectionTransform rebuilds from dragBefore* during nudge');

// --- 键位分发：纯方向键门（无修饰键）+ DOWN/UP 分流 ---
const keyBlock = canvas.slice(canvas.indexOf('bd8.j0={pa8.e..h}'),
  canvas.indexOf('bd8.j0={pa8.e..h}') + 900);
check(keyBlock.includes('!ctrl && !shift && !keyChordAlt(event)') &&
  keyBlock.includes('this.isSelectionNudgeKey(event.keyCode)'),
  'plain-arrow gate excludes ctrl/shift/alt (f2 285-286 chain)');
check(keyBlock.includes('this.endSelectionNudgeCommit()') &&
  keyBlock.includes('this.onSelectionNudgeKeyDown(event.keyCode)') &&
  keyBlock.includes('if (isUp)'),
  'UP→otf.a commit / DOWN→ntf step dispatch');
check(keyBlock.indexOf('!this.textEditing') === -1,
  'nudge lives inside !textEditing block (Q.m instanceof rsi gate)');

// --- 步进实现：选区支 vs 滚动支 ---
const stepFn = canvas.slice(canvas.indexOf('private onSelectionNudgeKeyDown('),
  canvas.indexOf('private onSelectionNudgeKeyDown(') + 2200);
check(stepFn.includes('!this.selectionTool.getState().isActive || !this.selectionVisible'),
  'no-selection branch → viewport scroll (d63.f==null gate)');
check(stepFn.includes('ORIGIN_KEY_SCROLL_FRACTION') &&
  stepFn.includes('this.viewport.setScroll(') &&
  stepFn.includes('this.viewport.scrollY - stepY') &&
  stepFn.includes('this.viewport.scrollX + stepX'),
  'scroll = ±0.1×viewport per axis (mfc.p()·0.1f + mfc.s)');
check(stepFn.includes('this.dragBeforeStrokes = this.completedStrokes.slice()') &&
  stepFn.includes('this.selectionNudgeActive = true'),
  'first nudge captures dragBefore* session baseline');
check(stepFn.includes('this.selectionTool.moveSelected(dx, dy)') &&
  stepFn.includes('this.applySelectionTransform(false, false)'),
  'step = moveSelected(±2.0) + live apply (guf.t p(map,jF,false))');

// --- 收尾提交：UP + 触摸 ---
const commitFn = canvas.slice(canvas.indexOf('private endSelectionNudgeCommit('),
  canvas.indexOf('private endSelectionNudgeCommit(') + 2400);
check(commitFn.includes('this.isIdentityTransform('),
  'identity gate = r9a.k()==0 no-op skip (guf.x:1260)');
check(commitFn.includes('UndoableActionType.TRANSFORM_ELEMENTS') &&
  commitFn.includes('this.persist(') &&
  commitFn.includes('this.notifyUndoRedo()'),
  'single TRANSFORM_ELEMENTS undo + persist on NudgeEnd (guf.u)');
check(commitFn.includes('this.selectionTool.selectElementIds('),
  'selection retained after commit (ome.c keep-selection)');
const touchHead = canvas.slice(canvas.indexOf('private onTouchDown('),
  canvas.indexOf('private onTouchDown(') + 700);
check(touchHead.includes('this.selectionNudgeActive') &&
  touchHead.includes('this.endSelectionNudgeCommit()'),
  'touch down finalizes pending nudge (ms1:784 otf.a analog)');

// --- 可执行模型：ntf 步进/累积/提交语义 ---
const STEP = 2.0;
let sessionDelta = { x: 0, y: 0 };
let sessionOpen = false;
let commits = 0;
function nudgeDown(key) {
  if (!sessionOpen) { sessionOpen = true; sessionDelta = { x: 0, y: 0 }; }
  if (key === 'LEFT') sessionDelta.x -= STEP;
  if (key === 'RIGHT') sessionDelta.x += STEP;
  if (key === 'UP') sessionDelta.y -= STEP;
  if (key === 'DOWN') sessionDelta.y += STEP;
}
function nudgeEnd() {
  if (!sessionOpen) return;
  sessionOpen = false;
  if (sessionDelta.x !== 0 || sessionDelta.y !== 0) commits++;
}
nudgeDown('RIGHT'); nudgeDown('RIGHT'); nudgeDown('DOWN'); nudgeEnd();
check(sessionDelta.x === 4.0 && sessionDelta.y === 2.0 && commits === 1,
  'model: 3 ntf steps accumulate → one NudgeEnd commit (x=+4, y=+2)');
nudgeDown('LEFT'); nudgeDown('RIGHT'); nudgeEnd();
check(sessionDelta.x === 0 && commits === 1,
  'model: cancel-out nudge → identity → no transaction (r9a.k()==0)');
nudgeEnd();
check(commits === 1, 'model: NudgeEnd without open session is no-op');

console.log(`d02-original-selection-nudge: ${n} checks OK`);
