// Phase 613 — 文本编辑撤销合并轨道（vnf.d op-type→track 指派等价）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   vnf.java:56-82 — d() 按 uq9.m()（haa op 类型）给每条 qnf 历史项指派
//     pnf 合并轨道：ordinal 7/8/12/13/14（INSERT_CHAR/INSERT_STRING/
//     MODIFY_STYLE/MODIFY_PARAGRAPH_STYLE/CLEAR_STYLE）→ pnf.J=INSERT_TEXT；
//     ordinal 9/10（REMOVE_CHAR/REMOVE_CHARS）→ pnf.K=REMOVE_TEXT；
//     ordinal 15（CREATE_INK）→ pnf.L=CREATE_INK；其余（含 11 REVIVE_CHARS）
//     → null 不可合并。
//   pnf.java:24-28 — INSERT_TEXT=2s、REMOVE_TEXT=2s、CREATE_INK=10ms。
//   vnf.java:489-516（f/undo）、562-599（g/redo）— 栈顶项先入组，随后逐项
//     比较：候选 b()==null → 停；轨道不等 → 停；相邻时间差 > 轨道窗 → 停。
//   vnf.java:607-613 — h() 仅刷新 canUndo/canRedo 标志。
// 语义：快速连续的同向文本编辑跨编辑会话仍合并为一步 undo；插入与删除
//   分属不同轨道，相邻异向编辑在轨道边界断开。
// Harmony 模型差异：原版富文本编辑器逐 op（每键击/样式改）入栈，Harmony
//   以「一次编辑会话 = 一个 REPLACE_ELEMENT action」提交。为在会话粒度上
//   逼近 vnf.d 的轨道指派，REPLACE_ELEMENT 的净前后缀 diff 充当 op 类型：
//   仅新增 → INSERT_TEXT；仅删除 → REMOVE_TEXT；混合/带笔画/多块 → NONE
//   （fail-closed）。ADD_ELEMENT ≈ CREATE_BLOCK（ordinal 22 → null），
//   保持 NONE。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const MGR = 'note/src/main/ets/rendering/UndoRedoManager.ets';
const OPT = 'note/src/main/ets/core/model/OpTypes.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const mgr = read(MGR);
const opt = read(OPT);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 轨道常量与 pnf 值一致（2s/2s/10ms） ---
check(mgr.includes('INSERT_TEXT_COALESCE_MS: number = 2000'), 'INSERT_TEXT window = 2s (pnf.J)');
check(mgr.includes('REMOVE_TEXT_COALESCE_MS: number = 2000'), 'REMOVE_TEXT window = 2s (pnf.K)');
check(mgr.includes('CREATE_INK_COALESCE_MS: number = 10'), 'CREATE_INK window = 10ms (pnf.L)');

// --- 轨道指派存在且按 vnf.d 语义分类 ---
check(mgr.includes('private coalesceTrackFor(action: UndoableAction)'),
  'coalesceTrackFor exists (vnf.d equivalent)');
check(mgr.includes('coalesceTrack: this.coalesceTrackFor(action)'),
  'createHistoryMetadata delegates track assignment');
const trackIdx = mgr.indexOf('private coalesceTrackFor(');
const track = mgr.slice(trackIdx, trackIdx + 2400);
check(track.includes("action.type === UndoableActionType.ADD_STROKE") &&
  track.indexOf('ADD_STROKE') < track.indexOf('REPLACE_ELEMENT'),
  'ADD_STROKE keeps CREATE_INK (haa 15 → pnf.L)');
check(track.includes('HistoryCoalesceTrack.INSERT_TEXT'),
  'added-only diff → INSERT_TEXT (haa 7/8 → pnf.J)');
check(track.includes('HistoryCoalesceTrack.REMOVE_TEXT'),
  'removed-only diff → REMOVE_TEXT (haa 9/10 → pnf.K)');
check(track.includes('action.beforeStrokes.length !== 0') &&
  track.includes('action.afterStrokes.length !== 0') &&
  track.includes('action.beforeElements.length !== 1') &&
  track.includes('action.afterElements.length !== 1'),
  'stroke-bearing or multi-element replaces stay untracked (fail-closed)');
check(track.includes('removed === 0 && added > 0') &&
  track.includes('added === 0 && removed > 0'),
  'prefix/suffix diff splits pure-insert vs pure-remove sessions');
check(track.indexOf('HistoryCoalesceTrack.NONE') < track.indexOf('HistoryCoalesceTrack.INSERT_TEXT'),
  'non-text actions default to NONE (vnf.d default → null)');

// --- 分组语义与 vnf.f/g 一致：锚点先入组、候选轨道窗、轨道相等、相邻时间差 ---
const peekIdx = mgr.indexOf('private peekGroup(');
check(peekIdx > 0, 'peekGroup exists (vnf.f/g equivalent)');
const peek = mgr.slice(peekIdx, peekIdx + 1500);
check(peek.includes('result.push({ action: anchor.action'),
  'stack-top anchor always enters the group (vnf D1 pop)');
check(peek.includes('coalesceWindow(candidate.history.coalesceTrack)'),
  'window comes from the candidate track (pnfVarB.a())');
check(peek.includes('window < 0'),
  'untracked candidate breaks the group (qnfVar2.b()==null → break)');
check(peek.includes('candidate.history.coalesceTrack !== anchor.history.coalesceTrack'),
  'track equality required (pnfVarB != qnfVar.b() → break)');
check(peek.includes('Math.abs(anchor.history.actionTime - candidate.history.actionTime) > window'),
  'adjacent timestamp diff bounded by track window (jS0 ≤ pnfVarB.a())');
check(peek.includes('candidate.action.noteId !== anchor.action.noteId') &&
  peek.includes('candidate.action.pageId !== anchor.action.pageId'),
  'note/page identity bounds the group (Harmony note-wide history adaptation)');

// --- OpTypes 轨道枚举镜像 pnf ---
check(opt.includes('Mirrors Notability 1.0.3 pnf') &&
  opt.includes('INSERT_TEXT = 1') && opt.includes('REMOVE_TEXT = 2') &&
  opt.includes('CREATE_INK = 3'),
  'HistoryCoalesceTrack mirrors pnf (NONE disables coalescing)');

console.log(`D02_ORIGINAL_TEXT_COALESCE_TRACK_OK TOTAL=${n} FAILED=0`);
