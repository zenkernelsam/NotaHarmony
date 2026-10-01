// Phase 1442 — wqf/urf 选择菜单轴终局裁决：剩余 4 枚未移植项全部坐实
// 原版证据（decompiled_1.4.2 urf.java:266-470 + wqf.java + h35.java + m36.java）：
//   wqf 23 枚枚举全映射：F=STYLE/G=COPY/H=CUT/I=DUPLICATE/J=GROUP/K=UNGROUP/
//     L=SEND_FORWARD/M=SEND_BACKWARD/N=SEND_TO_FRONT/O=SEND_TO_BACK/P=DELETE/
//     Q=CONVERT_TO_MATH/R=CONVERT_TO_TEXT/S=EDIT_MATH/T=SAVE_AS_STICKER/
//     U=CROP/V=FLIP_HORIZONTALLY/W=FLIP_VERTICALLY/X=LOCK/Y=UNLOCK/Z=DESELECT/
//     a0=MORE —— FIT_TO_PAGE(ordinal16, wqfVar17) 从未赋静态字段 = 死枚举。
//   Q=CONVERT_TO_MATH：h45.b(h35.e0)=td5("androidMathHandwritingRecognition")
//     defaults=false → 生产旗关 + iink 私有引擎，双重 fail-closed。
//   R=CONVERT_TO_TEXT：无旗门但分发链入 MyScript iink → fail-closed。
//   T=SAVE_AS_STICKER：h45.b(h35.z0)=STICKERS rd5 InternalUserOnly → 生产恒不可达。
// Harmony：四行全部缺省（正确）；urf 裁决注释登记于 SelectionOverlay。
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

// --- 1) Harmony SelectionMenuAction 无四枚死/关行 ---
const enumSlice = overlay.slice(overlay.indexOf('export enum SelectionMenuAction'),
  overlay.indexOf('@Component'));
for (const dead of ['CONVERT_TO_MATH', 'CONVERT_TO_TEXT', 'SAVE_AS_STICKER', 'FIT_TO_PAGE']) {
  check(!new RegExp(`\\b${dead}\\s*=`).test(enumSlice),
    `SelectionMenuAction 无 ${dead} 枚举（fail-closed/死项）`);
}
// 分发侧亦无对应 case 残留
check(!canvas.includes('SelectionMenuAction.CONVERT_TO_MATH') &&
  !canvas.includes('SelectionMenuAction.CONVERT_TO_TEXT') &&
  !canvas.includes('SelectionMenuAction.SAVE_AS_STICKER') &&
  !canvas.includes('SelectionMenuAction.FIT_TO_PAGE'),
  'NoteCanvasView 分发无四项残留');

// --- 2) 裁决注释登记（urf 精证） ---
check(overlay.includes('P1442 终局裁决') && overlay.includes('androidMathHandwritingRecognition'),
  'overlay 注释登记 CONVERT_TO_MATH td5 旗（defaults=false）');
check(overlay.includes('oim.b') && overlay.includes('HIGHLIGHTER'),
  'overlay 注释登记 CONVERT_TO_TEXT oim.b(k!=HIGHLIGHTER) 行门 + iink 链');
check(overlay.includes('STICKERS rd5 InternalUserOnly') || overlay.includes('STICKERS'),
  'overlay 注释登记 SAVE_AS_STICKER rd5 InternalUserOnly');
check(overlay.includes('wqfVar17') && overlay.includes('死项'),
  'overlay 注释登记 FIT_TO_PAGE 死枚举证据');

// --- 3) 既往门控未回退 ---
check(canvas.includes('!state.supportsDeselectMode &&\n      state.selectedMathIds.length === 1') ||
  /selectionCanEditMath = !state\.supportsDeselectMode/.test(canvas),
  'P1441 lsf 门保留（EDIT_MATH）');
check(overlay.includes('if (this.lockedOnly)'),
  'P1441 lockedOnly 单行保留');
check(canvas.includes('this.selectionCanReorder = !(state.supportsDeselectMode'),
  'P1440 canReorder f() 门保留');
check(canvas.includes('this.selectionCanDeselect = state.supportsDeselectMode'),
  'P1439 canDeselect isf 门保留');

// --- 4) 枚举完整（19 实项 + deselect 双控件），无空缺 ---
const enumCount = (enumSlice.match(/= \d+,/g) || []).length;
check(enumCount === 20, `SelectionMenuAction 枚举基数=20（${enumCount}）`);

console.log(`PHASE1442_MENU_ADJUDICATION_OK TOTAL=${total} FAILED=0`);
