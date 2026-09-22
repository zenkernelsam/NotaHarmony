// Phase 616 — UNGROUP 仅 gtc 单组选区可触发（dhb case5 ftc 死路径）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   dhb.java:17655-17672 — case5(UNGROUP, dsc=5)：
//     gtc → listN0 = l0(gtc.a)，非空才派发 wsc 协程 + fvb.a()；
//     ftc → 仅计算 H1(ftc.m) 首组成员集 listN0 后直接 return
//     mof.a——不派发 wsc，UNGROUP 对多选壳是死操作；
//     itc/etc → 落到 o14.t() 不可达分支，同样不执行。
//   即：混选 {组+其他元素} 在原版里不能解组——只有整个选区
//   恰为单个组（顶层项=[组id]）时解组发生。
// Harmony 对齐：selectionCanUngroup / ungroupSelectedElements 均要求
//   authoringMembers = [所选组id]（顶层项恰一项且为该组）；
//   混选含单组（authoring 长度≥2）不再显示/执行 UNGROUP。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const OVL = 'note/src/main/ets/ui/components/SelectionOverlay.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const view = read(VIEW);
const ovl = read(OVL);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- selectionCanUngroup：顶层项恰为 [组id] ---
const gateIdx = view.indexOf('this.selectionCanUngroup =');
check(gateIdx > 0, 'selectionCanUngroup assignment present');
const gate = view.slice(gateIdx, gateIdx + 500);
check(gate.includes('groupMembers !== null && groupMembers.length === 1'),
  'canUngroup requires exactly one top-level item (gtc equivalence)');
check(gate.includes("groupMembers[0] === state.selectedGroupIds[0]"),
  'the single top-level item must be the selected group id');
check(gate.includes('state.selectedGroupIds.length === 1'),
  'still requires exactly one selected group');
check(gate.includes('findSelectionGroup') && gate.includes('resolveOriginalSelectedGroupLeaves'),
  'keeps group-exists + leaves-resolvable checks (listN0 non-empty parity)');

// --- ungroupSelectedElements 执行端同门槛 ---
const ungIdx = view.indexOf('private ungroupSelectedElements(');
check(ungIdx > 0, 'ungroupSelectedElements present');
const ung = view.slice(ungIdx, ungIdx + 1200);
check(ung.includes('resolveOriginalGroupAuthoringMembers'),
  'runtime guard reuses authoring-members resolution');
check(ung.includes('authoring.length !== 1') &&
  ung.includes('authoring[0] !== state.selectedGroupIds[0]'),
  'runtime guard rejects mixed selections containing one group (ftc dead path)');
check(ung.includes('state.selectedGroupIds.length !== 1'),
  'runtime guard still requires single selected group');

// --- 菜单侧仍条件渲染 ---
check(ovl.includes('if (this.canUngroup)'),
  'UNGROUP menu item stays conditional (hidden for mixed selections)');

// --- 对齐注释 ---
check(view.includes('dhb case5'), 'code cites dhb case5 evidence');

console.log(`D02_ORIGINAL_UNGROUP_GATE_OK TOTAL=${n} FAILED=0`);
