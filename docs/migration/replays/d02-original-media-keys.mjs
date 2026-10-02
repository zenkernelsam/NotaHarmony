// Phase 1471 — 1.4.2 音频回放媒体键（f2 兜底链尾 → q5d.k.h/i/z）。
// Original evidence (decompiled_1.4.2):
//   f2.java:282-288 — db8.r&&db8.s&&pa8.a(n,h=DPAD_RIGHT) → q5d.k.h()；
//     db8.r&&db8.s&&pa8.a(n,g=DPAD_LEFT) → q5d.k.i()；
//     !q&&!r&&!s&&pa8.a(n,M=SPACE)（外层 else 支）UP → q5d.k.z()。
//   xke.java:253-269 — h()=min(p+10000,q 总时长)→w(d)；
//     i()=max(p−10000,0)→w(d)；q5d.p=累计播放位 ms。
//   xke.java:567-590 — w(d)：累计位→录音索引 i（q5d.d(i) 分段偏移）
//     → pv4.z(i, localMs) 跨录音 seek + q5d.p/d63 更新。
//   xke.java:152-179,626-630 — z()=m==e6d.F(PLAYING)→C() 暂停
//     （pv4.u()，PAUSED 态 no-op）；否则 D() 播放当前 q7d
//     （录音列表空 → log+no-op）。e6d={F:PLAYING,G:PAUSED,H:STOPPED}。
// Harmony：onCanvasKeyEvent !textEditing 块尾部——Ctrl+Shift+←/→ →
//   onKeyRecordingSeekBy(∓10000)；纯 SPACE → onKeyRecordingPlayPause()。
//   NotePage：seekBy→min/max 钳制后 seekRecordingTimeline（w(d) 等价）；
//   playPause→playbackSnapshot.recordingId ?? 首条可见录音 →
//   toggleRecording（C()/D() 等价）。
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

// --- 常量：SPACE 键码 + ±10s 步长 ---
check(chords.includes('ORIGIN_KEYCODE_SPACE: number = 2050'),
  'Harmony SPACE=2050 pinned (pa8.M = ofk.e(62))');
check(chords.includes('ORIGIN_RECORDING_SEEK_STEP_MS: number = 10000'),
  'q5d.k.h()/i() ±10000ms seek step pinned');
check(chords.includes('q5d.k.i()') && chords.includes('q5d.k.h()') &&
  chords.includes('q5d.k.z()'),
  'constants carry q5d.k.h/i/z evidence comment');

// --- 回调 prop 声明 ---
check(canvas.includes('onKeyRecordingSeekBy: (deltaMs: number) => void') &&
  canvas.includes('onKeyRecordingPlayPause: () => void'),
  'canvas declares seek/play-pause key callback props');

// --- 分发支：Ctrl+Shift+←/→ seek；纯 SPACE play/pause ---
const anchor = 'q5d.k.i()/h()';
const start = canvas.indexOf(anchor);
check(start > 0, 'media branch annotated with q5d.k evidence');
const block = canvas.slice(start, start + 1400);
check(block.includes('ctrl && shift') &&
  block.includes('ORIGIN_KEYCODE_DPAD_LEFT') &&
  block.includes('ORIGIN_KEYCODE_DPAD_RIGHT'),
  'Ctrl+Shift+LEFT/RIGHT gate (db8.r&&db8.s&&pa8.g/h 等价)');
check(block.includes('ORIGIN_KEYCODE_DPAD_LEFT ?') &&
  block.includes('-ORIGIN_RECORDING_SEEK_STEP_MS : ORIGIN_RECORDING_SEEK_STEP_MS'),
  'LEFT→−10s (k.i) / RIGHT→+10s (k.h) dispatch');
check(block.includes('this.onKeyRecordingSeekBy(') && block.includes('if (isUp)'),
  'seek fires on UP only (lxm.a(o,1))');
check(block.includes('!ctrl && !shift && !keyChordAlt(event)') &&
  block.includes('event.keyCode === ORIGIN_KEYCODE_SPACE'),
  'plain SPACE gate excludes all modifiers (f2 !q&&!r&&!s&&M)');
check(block.includes('this.onKeyRecordingPlayPause()'),
  'SPACE UP → play/pause toggle (q5d.k.z())');
check(block.match(/return true/g) !== null,
  'media branches consume both DOWN and UP (无 b2=0 落点)');
const textEditGate = canvas.indexOf('if (!this.textEditing) {');
check(textEditGate > 0 && textEditGate < start,
  'media branches inside !textEditing block (!rsi 门)');
// 链序：seek/space 支在 PAGE_UP/DOWN 支之后（f2 尾链序）
check(start > canvas.indexOf('pa8.a0(92=PAGE_UP)'),
  'media branches follow page-scroll branch (f2 链序)');

// --- NotePage 接线：钳制语义 + 播放切换 ---
check(page.includes('onKeyRecordingSeekBy: (deltaMs: number): void => {') &&
  page.includes('Math.max(this.playbackCumulativePositionMs + deltaMs, 0)') &&
  page.includes('Math.min(') && page.includes('total)'),
  'NotePage seek = clamp(pos+delta, 0, totalDuration) (xke.h/i+w 等价)');
check(page.includes('this.seekRecordingTimeline(target)'),
  'seek routes to cumulative timeline (跨录音定位)');
check(page.includes('onKeyRecordingPlayPause: (): void => {') &&
  page.includes('this.playbackSnapshot.recordingId') &&
  page.includes('this.toggleRecording(recordingId)'),
  'SPACE toggle → current-or-first recording → toggleRecording (z() 等价)');
check(page.indexOf('visiblePlaybackRecordings()') > 0 &&
  page.includes('recordingId === null') ,
  'no recordings → no-op (D() 空列表 log+no-op 等价)');

// --- 可执行模型：xke.h/i 钳制 + z() 状态机 ---
function seekH(pos, dur) { const t = pos + 10000; return Math.min(t, dur); }
function seekI(pos) { return Math.max(pos - 10000, 0); }
check(seekH(5000, 60000) === 15000 && seekH(55000, 60000) === 60000,
  'model: h()=min(pos+10s, duration)');
check(seekI(15000) === 5000 && seekI(5000) === 0,
  'model: i()=max(pos−10s, 0)');
function z(state, hasRecordings) {
  if (state === 'PLAYING') return 'pause';
  if (!hasRecordings) return 'noop';
  return 'play';
}
check(z('PLAYING', true) === 'pause' && z('PAUSED', true) === 'play' &&
  z('STOPPED', false) === 'noop',
  'model: z()=PLAYING→C()/else D();empty list→no-op');

console.log(`d02-original-media-keys: ${n} checks OK`);
