// D05 原版 media_object_corners 设置 + ROUND 圆角渲染 fail-closed — Phase 704（ADR-0653）
// corner 是 BlockCommon LWW register（BlockCornerType 枚举 {0,1}），
// Harmony 数据面已完整 round-trip；设置项与 ROUND 视觉渲染登记
// fail-closed（SHARP=0 确定默认，ROUND 像素半径无静态证据不猜）。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const strings = read(`${JADX}/resources/res/values/strings.xml`);
const ry0 = read(`${JADX}/sources/defpackage/ry0.java`);
const td8 = read(`${JADX}/sources/defpackage/td8.java`);
const z22 = read(`${JADX}/sources/defpackage/z22.java`);
const y22 = read(`${JADX}/sources/defpackage/y22.java`);

const elements = read('note/src/main/ets/core/model/ElementTypes.ets');
const createBlock = read('note/src/main/ets/data/OriginalCreateBlockOperation.ets');
const modifyBlock = read('note/src/main/ets/data/OriginalModifyBlockOperation.ets');
const imagePlan = read('note/src/main/ets/core/model/OriginalImageInsertPlan.ets');
const mathPlan = read('note/src/main/ets/core/model/OriginalMathInsertPlan.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 原版证据 ---
check(strings.includes('feature_settings__media_object_corners') &&
  strings.includes('feature_settings__rounded') &&
  strings.includes('feature_settings__sharp'),
  'media-object-corners setting with Rounded/Sharp options');
check(ry0.includes('getCorner()Lcom/gingerlabs/notability/core/flatbuffers/BlockCornerType') &&
  ry0.includes('cornerRegister'),
  'corner is a BlockCommon LWW register typed BlockCornerType (enum)');
check(td8.includes('corner=' + '" + k()') && td8.includes('k() == td8Var.k()'),
  'ModifyBlock serializes + compares the corner register');
check(z22.includes('feature_settings__media_object_corners') &&
  y22.includes('feature_settings__rounded') && y22.includes('feature_settings__sharp'),
  'settings UI renders the label + both options');

// --- Harmony 数据面（round-trip 已对齐）---
check(elements.includes('corner?: number') && elements.includes('corner: number;'),
  'TEXT/IMAGE/MATH elements carry the corner field');
check(createBlock.includes('corner: normalizeOriginalEnum(table.readUint8(1, 0), 1)') &&
  createBlock.includes("'create_corner': payload.corner") &&
  createBlock.includes('corner: payload.corner'),
  'CreateBlock reads corner enum {0,1} + persists create_corner + applies to elements');
check(modifyBlock.includes('corner: StoredRegister<number>') &&
  modifyBlock.includes('table.hasField(1)') &&
  modifyBlock.includes('updatedElement.corner'),
  'ModifyBlock LWW-merges the corner register onto elements');

// --- Harmony 边界（登记项）---
check(imagePlan.includes('corner: 0') && mathPlan.includes('corner: 0') &&
  canvas.includes('element.corner = 0'),
  'all local inserts seed corner=0 (SHARP) — the determined default');
check(!elements.includes('cornerRadius') && !canvas.includes('roundRect'),
  'no renderer consumes corner for ROUND clipping (unverifiable radius — not guessed)');

console.log(`D05_ORIGINAL_MEDIA_CORNERS_FAIL_CLOSED_REPLAY_OK TOTAL=${total} FAILED=0`);
