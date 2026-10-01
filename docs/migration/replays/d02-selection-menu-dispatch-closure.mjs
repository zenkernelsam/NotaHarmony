// Phase 1444 — sqf 菜单动作分发侧审计收口（urf 菜单轴终局之二）
// 原版证据（decompiled_1.4.2 sqf.java wqf.ordinal() switch）：
//   case0 STYLE: lsf+vvh→hrf 文本框事件（S0 调试旗，生产藏）；否则
//     c0→mn7 笔画首扫 + v0→f5g 形状二扫，任一命中出 STYLE。
//   case1 COPY: ot2.d(msf) 内部 omeVar.a() 自清选区。
//   case2/3 CUT/DUP: qrf 协程 → ot2.e/ot2.a；a()=清选区→偏移粘贴→
//     粘贴内容 j01 产 isf（Harmony 一致）。
//   case4 GROUP: isf 且 N3(q+m)≥2 → p2d 组 + H.a() 清选区。
//   case5 UNGROUP: jsf→x2(jsf.a)；isf 纯单组→z2(m 单例)；trf 解组。
//   case6-9 SEND_*: urfVar.F(g0c/naf) z-order 位移 + 清选区不见——
//     实际 F 内位移后选区保持（原版本组选区 SEND 即持）。
//   case10 DELETE: p2d(24)+H.a() 清选区。
//   case13 EDIT_MATH: lsf+cv9→gv9 编辑事件 + urfVar.H() 面板态。
//   case15 CROP: lsf+l97→f11 参数→sbe 会话 + erf 状态。
//   case16 FIT_TO_PAGE: throw NotImplementedError（死支）。
//   case17/18 FLIP: psb(h(),ei5.F/G)+H.a() 清选区。
//   case19/20 LOCK|UNLOCK: lsf→ybn 实体翻转 t()；非 lsf→A() 方向→hp8
//     批量锁 + omeVar2.a() 清选区。
//   case21 DESELECT: dqd(16) 事件→isf.h 模式位 → m 存快照。
//   case22 MORE: frf.b 子菜单展开位翻转（本地 UI 态）。
// Harmony：全部一致或已登记 fail-closed（CONVERT_*/STICKER/FIT_TO_PAGE）。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');

const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const tool = read('note/src/main/ets/rendering/SelectionTool.ets');
const overlay = read('note/src/main/ets/ui/components/SelectionOverlay.ets');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 1) 动作后清选区语义（原版 omeVar.a()=hmb.g(null)） ---
const flipIdx = canvas.indexOf('private flipSelected(');
check(flipIdx > 0 && canvas.slice(flipIdx, flipIdx + 2600).includes('clearSelectionWithRegisterReset'),
  'FLIP 后清选区（sqf case17/18 → H.a()）');
const groupIdx = canvas.indexOf('private groupSelectedElements(');
check(groupIdx > 0 && canvas.slice(groupIdx, groupIdx + 2600).includes('clearSelectionWithRegisterReset'),
  'GROUP 后清选区（sqf case4 → H.a()）');
const ungroupIdx = canvas.indexOf('private ungroupSelectedElements(');
check(ungroupIdx > 0 && canvas.slice(ungroupIdx, ungroupIdx + 3200).includes('clearSelectionWithRegisterReset'),
  'UNGROUP 后清选区（sqf case5）');
const lockIdx = canvas.indexOf('private setSelectedPositionLocked(');
check(lockIdx > 0 && canvas.slice(lockIdx, lockIdx + 7000).includes('clearSelectionWithRegisterReset'),
  'LOCK/UNLOCK 后清选区（sqf case19/20 → omeVar2.a()）');

// --- 2) COPY 自清（ot2.d 内部 omeVar.a()） ---
const copyIdx = canvas.indexOf("action === SelectionMenuAction.COPY");
check(copyIdx > 0 && canvas.slice(copyIdx, copyIdx + 900).includes('clearSelectionWithRegisterReset'),
  'COPY 后清选区（sqf case1 → ot2.d 内 omeVar.a()）');

// --- 3) GROUP ≥2 门（sqf case4 arrayListN3.size()>=2） ---
check(canvas.slice(groupIdx, groupIdx + 1600).includes('members.length < 2'),
  'GROUP 分发保留 ≥2 成员门');

// --- 4) UNGROUP 恰单组门（sqf case5 jsf/isf-纯单组） ---
check(canvas.slice(ungroupIdx, ungroupIdx + 1600).includes('selectedGroupIds.length !== 1'),
  'UNGROUP 分发保留恰单组门');

// --- 5) DESELECT → deselectMode 进入 + 快照（sqf case21 dqd+m） ---
check(canvas.includes('enterDeselectMode') && tool.includes('preDeselectSelection'),
  'DESELECT→deselectMode + preDeselect 快照（sqf case21 dqd→isf.h+m）');

// --- 6) EDIT_MATH → 编辑器入口（sqf case13 gv9+H()） ---
check(canvas.includes("action === SelectionMenuAction.EDIT_MATH") &&
  canvas.slice(canvas.indexOf('action === SelectionMenuAction.EDIT_MATH'),
    canvas.indexOf('action === SelectionMenuAction.EDIT_MATH') + 300)
    .includes('startMathEditing'),
  'EDIT_MATH → startMathEditing（sqf case13 gv9 事件+H() 面板态）');

// --- 7) 死项/fail-closed 分发零残留 ---
check(!canvas.includes('FIT_TO_PAGE') && !canvas.includes('SAVE_AS_STICKER'),
  'FIT_TO_PAGE/SAVE_AS_STICKER 分发零残留');

// --- 8) MORE 平铺适配登记 ---
check(overlay.includes('单行全量列出') || overlay.includes('msc.b'),
  'MORE 子菜单平铺适配注释保留');

console.log(`PHASE1444_DISPATCH_AUDIT_OK TOTAL=${total} FAILED=0`);
