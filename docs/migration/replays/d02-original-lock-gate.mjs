// Phase 617 — LOCK/UNLOCK 门槛对齐 xsc.k + dhb case18/19 itc 分支。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   xsc.java:216-240 — k(ktc)：解析 ktc.h() 全部成员；任一成员
//     resolve 非 m4d（笔画 s06、oy0 块 hp5/r08）→ null 死路径；
//     cih.a(m4d)（n5d 形状）成员存在才返回 z2=全部已锁→UNLOCK。
//   n5d.java:8 — n5d implements m4d（唯一 m4d 元素类型）；
//     hp5.java:8 / r08.java:4 — 图像/文本/数学块是 oy0 非 m4d。
//   dhb.java:17997-18034 — case18/19(LOCK/UNLOCK)：itc 单元素直接
//     u5j.n(oy0)/u5j.x(m4d+cih.a) 产出 op——单 oy0 块/形状可锁，
//     s06 笔画 objX=null 死操作；非 itc 用 xsc.k 判向并按
//     t()!=z15 过滤后派发 vz6。
// Harmony 对齐：多选/单组需所有成员（含组叶子）都是形状；
//   单元素须 lockable（oy0/m4d 等价：形状/文本/图像/数学）——
//   单笔画不再显示/执行 LOCK。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const OVL = 'note/src/main/ets/ui/components/SelectionOverlay.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const view = read(VIEW);
const ovl = read(OVL);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 门槛：成员全形状（xsc.k）或单个可锁元素（itc） ---
const gateIdx = view.indexOf('this.selectionCanLock =');
check(gateIdx > 0, 'selectionCanLock assignment present');
const gate = view.slice(gateIdx - 1800, gateIdx + 400);
check(gate.includes('resolveOriginalSelectedGroupLeaves'),
  'lock gate resolves selected-group leaves (xsc.k iterates ktc.h() members)');
check(gate.includes('selectedEntityIds.concat(groupLeafIds)'),
  'flat member set = ungrouped entities + group leaves (ktc.h() equivalent)');
check(gate.includes('shapeIdSet.has(id)'),
  'all-members-are-shapes check (m4d/n5d equivalence)');
check(view.includes('this.selectionCanLock = allMembersAreShapes ||\n' +
  '      (state.selectedGroupIds.length === 0 && selectedCount === 1 && lockableCount === 1)'),
  'canLock = all-shapes members OR single non-stroke element (stroke excluded)');

// --- 方向：组内成员全锁→UNLOCK ---
check(gate.includes('allMemberShapesLocked') &&
  view.includes('this.selectionPositionLocked = allMemberShapesLocked ||'),
  'positionLocked direction covers resolved group-member shapes');

// --- 执行端：组叶子并入生效形状集合 ---
const lockIdx = view.indexOf('private setSelectedPositionLocked(');
check(lockIdx > 0, 'setSelectedPositionLocked present');
const exec = view.slice(lockIdx, lockIdx + 1400);
check(exec.includes('effectiveShapeIds') && exec.includes('groupLeafIds'),
  'shape toggle set includes resolved group-member leaves');
check(exec.includes('!effectiveShapeIds.has(shape.id)'),
  'shape loop uses effective (group-expanded) id set');
check(exec.includes('(shape.positionLocked === true) === locked'),
  'per-shape t()!=z15 filter preserved (only differing shapes toggle)');

// --- 单笔画不可锁（itc 死路径对齐） ---
check(!view.includes('selectedCount === 1 && state.selectedGroupIds.length === 0);\n    this.selectionPositionLocked'),
  'old gate counting strokes removed');
check(ovl.includes('if (this.canLock)'),
  'LOCK menu item stays conditional');

console.log(`D02_ORIGINAL_LOCK_GATE_OK TOTAL=${n} FAILED=0`);
