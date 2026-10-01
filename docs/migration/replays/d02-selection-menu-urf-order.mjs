// Phase 1440 — 选择菜单行序 + SEND_* f()门控按 urf 装配器对齐
// 原版证据（decompiled_1.4.2 urf.java:260-470 + wqf.java 枚举映射）：
//   主行序=[CROP?](l97 图像单元素)/[EDIT_MATH?](cv9 数学单元素)/
//          [STYLE?](可样式化 ink 扫描)/COPY/CUT/DUPLICATE/
//          [GROUP|UNGROUP?](jsf→UNGROUP；isf 单组→UNGROUP、≥2→GROUP)/
//          [LOCK|UNLOCK?](h35.I=POSITION_LOCKED td5 灰度旗)/
//          [DESELECT?](isf 专属)/DELETE/[MORE?](子菜单非空)
//   MORE 子菜单序=FLIP_H/FLIP_V/CONVERT_TO_MATH/CONVERT_TO_TEXT/
//          SAVE_AS_STICKER/SEND_TO_FRONT/SEND_TO_BACK/SEND_FORWARD/SEND_BACKWARD
//   SEND_* 门控：msfVar.f()（z-orderable 集）非空——isf.f()=q=g−p
//   （选中叶子减组内成员），纯组绘制选区 q 空 → 不产四行；
//   jsf.f()=成员叶子、lsf.f()=单实体，恒非空。
// Harmony：单行平铺 MORE 子菜单（既有适配）+ canReorder=isf.q 空探测 +
//   原序平铺（fail-closed 项 CONVERT_*/STICKER/FIT_TO_PAGE 缺省）。
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

const idx = (anchor) => overlay.indexOf(anchor);

// --- 1) 主行序（urf 发射序平铺）---
const order = [
  'menu Crop clicked', 'menu Edit Math clicked', 'menu Style clicked',
  'menu Copy clicked', 'menu Cut clicked', 'menu Duplicate clicked',
  'menu Paste clicked', 'menu Group clicked', 'menu Ungroup clicked',
  'menu Lock clicked', 'menu Deselect clicked', 'menu Del clicked',
  'menu FlipH clicked', 'menu FlipV clicked', 'menu ToFront clicked',
  'menu ToBack clicked', 'menu Fwd clicked', 'menu Bwd clicked',
];
for (let i = 1; i < order.length; i++) {
  check(idx(order[i - 1]) >= 0 && idx(order[i]) > idx(order[i - 1]),
    `menu order: ${order[i - 1]} before ${order[i]}`);
}

// --- 2) SEND_* 四行 canReorder 门控（isf.q 空 → 隐藏）---
check(/@Prop canReorder:\s*boolean/.test(overlay),
  'SelectionOverlay exposes canReorder prop');
check(/if \(this\.canReorder\)[\s\S]*?menu ToFront clicked[\s\S]*?menu Bwd clicked/.test(overlay),
  'SEND_* block gated on canReorder');
check(/@State selectionCanReorder/.test(canvas) &&
  /selectionCanReorder = !\(state\.supportsDeselectMode &&\s*\n?\s*state\.selectedGroupIds\.length > 0/.test(canvas),
  'selectionCanReorder mirrors isf.q-emptiness (all leaves inside selected groups)');
check(/canReorder: this\.selectionCanReorder/.test(canvas),
  'overlay bound to selectionCanReorder');

// --- 3) h35.I=POSITION_LOCKED td5 灰度旗登记（生产缺省 false，本地实现保留）---
check(overlay.includes('POSITION_LOCKED') && overlay.includes('androidPositionLocked'),
  'overlay comment records POSITION_LOCKED rollout gate');
check(canvas.includes('androidPositionLocked'),
  'lock-gate comment records the remote key name');

// --- 4) hsf→isf/urf 语义注释保留 ---
check(overlay.includes('DESELECT 仅 isf 装配'),
  'DESELECT isf-only comment retained');
check(/if \(this\.canDeselect\)[\s\S]*?SelectionMenuAction\.DESELECT/.test(overlay),
  'DESELECT row still gated on canDeselect (P1439)');

// --- 5) 文档闭环 ---
assert.ok(read('docs/migration/evidence/phase-1440-selection-menu-order.md').length > 0,
  'evidence doc exists');
assert.ok(read('docs/migration/adr/ADR-1375-selection-menu-order.md').includes('urf'),
  'ADR-1375 records urf ordering adjudication');

console.log(`selection menu urf-order: ${total}/${order.length - 1 + 8} checks green`);
