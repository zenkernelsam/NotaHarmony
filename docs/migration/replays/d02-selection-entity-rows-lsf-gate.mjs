// Phase 1441 — CROP/EDIT_MATH/FLIP_H/FLIP_V 实体专属行 lsf 门控 +
//   单元素已锁 → [UNLOCK] 单行菜单
// 原版证据（decompiled_1.4.2 urf.java:243-470）：
//   hv6VarP1 仅经 lsf（单元素点选）推导：`lsfVar2=msfVar instanceof lsf …`
//   `hv6VarP1=zq.p0(r0b, lsfVar2.a, 6)`——isf/jsf/hsf 下恒为 null。
//   故 CROP（z6: hv6VarP1 instanceof l97 图像）、EDIT_MATH（cv9 数学）、
//   FLIP_H/FLIP_V（z6）全部为 lsf 专属：套索恰圈单元素的 isf 不产这些行。
//   另：urf z 支（h45.b(h35.I)=POSITION_LOCKED 旗 + lsf + cjm.h 实体已锁）
//   → xqf(oag.x2(wqf.Y), ∅)——菜单仅 UNLOCK 一行。
// Harmony：三门以 !supportsDeselectMode（非 isf 型）前置；
//   canFlipImageSelection 收紧为恰一图（原版 l97 单实体语义）；
//   selectionLockedOnly=lsf 型+恰一可锁实体已锁+无组 → [UNLOCK] 单行。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');

const overlay = read('note/src/main/ets/ui/components/SelectionOverlay.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 1) CROP/EDIT_MATH/FLIP 仅 lsf 型（!isf）可达 ---
check(/this\.selectionCanFlip = !state\.supportsDeselectMode &&\s*this\.canFlipImageSelection\(/
  .test(canvas),
  'selectionCanFlip 以 !supportsDeselectMode 前置（lsf 专属）');
check(/this\.selectionCanCrop = !state\.supportsDeselectMode &&\s*this\.canCropImageSelection\(/
  .test(canvas),
  'selectionCanCrop 以 !supportsDeselectMode 前置（lsf 专属）');
check(/this\.selectionCanEditMath = !state\.supportsDeselectMode &&\s*state\.selectedMathIds\.length === 1/
  .test(canvas),
  'selectionCanEditMath 以 !supportsDeselectMode 前置（lsf 专属）');

// --- 2) FLIP 恰一图（原版 hv6VarP1 instanceof l97 单实体） ---
const flipIdx = canvas.indexOf('private canFlipImageSelection(');
assert.ok(flipIdx > 0);
const flipSlice = canvas.slice(flipIdx, flipIdx + 1600);
check(flipSlice.includes('imageIds.length !== 1'),
  'canFlipImageSelection 收紧为恰一图（urf z6 单实体语义）');

// --- 3) 实体专属行 lsf 证据注释在位 ---
check(canvas.includes('hv6VarP1=zq.p0(r0b, lsf.a) 推导') &&
  canvas.includes('仅 lsf 单元素点选可达'),
  'updateSelectionOverlay 记录 urf lsf-专属证据注释');

// --- 4) lockedOnly 单行 UNLOCK（urf z 支） ---
check(/this\.selectionLockedOnly = !state\.supportsDeselectMode &&\s*\n\s*state\.selectedGroupIds\.length === 0 && selectedCount === 1/
  .test(canvas),
  'selectionLockedOnly = 非 isf + 无组 + 恰一可锁已锁实体');
const lockOnlySrc = canvas.slice(canvas.indexOf('this.selectionLockedOnly = '), canvas.indexOf('this.selectionLockedOnly = ') + 500);
check(lockOnlySrc.includes('lockedCount === 1') && lockOnlySrc.includes('lockableCount === 1'),
  'selectionLockedOnly 复核 lockedCount/lockableCount===1');
check(overlay.includes('@Prop lockedOnly: boolean = false'),
  'SelectionOverlay 声明 lockedOnly prop');
check(canvas.includes('lockedOnly: this.selectionLockedOnly'),
  'NoteCanvasView 绑定 lockedOnly 镜像');
check(/if \(this\.lockedOnly\) \{\s*\n\s*items\.push\(\{ value: \$r\('app\.string\.unlock'\)[\s\S]*?SelectionMenuAction\.LOCK\); \} \}\);\s*\n\s*return items;/
  .test(overlay),
  'lockedOnly 时菜单仅 UNLOCK（LOCK 合并行 positionLocked 态）单行即返回');

// --- 5) 单行菜单位于实体专属行之前（urf z 支早退） ---
const overlayOrder = overlay;
const lockOnlyIdx = overlayOrder.indexOf('if (this.lockedOnly)');
const cropIdx = overlayOrder.indexOf('if (this.canCrop)');
check(lockOnlyIdx > 0 && cropIdx > 0 && lockOnlyIdx < cropIdx,
  'lockedOnly [UNLOCK] 单行在 CROP/实体专属行之前短路');

// --- 6) 注释引证在位 ---
check(overlay.includes('urf z 支') && overlay.includes('xqf([UNLOCK]') ||
  overlay.includes('oag.x2(wqf.Y)'),
  'overlay 注释记录 urf z 支证据');

// --- 7) 既往门控未回退 ---
check(canvas.includes('this.selectionCanDeselect = state.supportsDeselectMode'),
  'P1439 canDeselect isf 门保留');
check(canvas.includes('this.selectionCanReorder = !(state.supportsDeselectMode'),
  'P1440 canReorder f() 门保留');
check(overlayOrder.indexOf('menu Fwd clicked') > overlayOrder.indexOf('menu ToBack clicked'),
  'P1440 SEND_* urf 序保留（Fwd 在 ToBack 后）');

console.log(`PHASE1441_LSF_ENTITY_ROWS_OK TOTAL=${total} FAILED=0`);
