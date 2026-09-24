// D05 原版 text_box_paper 文档默认设置 fail-closed — Phase 705（ADR-0654）
// paper 是 TEXT 块 LWW register（flatbuffers Paper），Harmony
// 数据+渲染面已完整；仅本地偏好项缺失（新文本固定 paper:null =
// 确定默认）。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const strings = read(`${JADX}/resources/res/values/strings.xml`);
const cie = read(`${JADX}/sources/defpackage/cie.java`);
const z22 = read(`${JADX}/sources/defpackage/z22.java`);

const elements = read('note/src/main/ets/core/model/ElementTypes.ets');
const createBlock = read('note/src/main/ets/data/OriginalCreateBlockOperation.ets');
const textRenderer = read('note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const settingsStore = read('note/src/main/ets/data/EditorSettingsStore.ets');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 原版证据 ---
check(strings.includes('feature_settings__document_defaults') &&
  strings.includes('feature_settings__text_box_paper'),
  'Document defaults section carries the text_box_paper row');
check(cie.includes('getPaper()Lcom/gingerlabs/notability/core/flatbuffers/Paper') &&
  cie.includes('paperRegister') && cie.includes('TextBlockImpl'),
  'TEXT block paper is an LWW register (flatbuffers Paper)');
check(z22.includes('feature_settings__text_box_paper') &&
  z22.includes('feature_settings__document_defaults'),
  'settings UI renders the document-defaults row');

// --- Harmony 数据+渲染面 ---
check(elements.includes('paper?: PagePaperBackground | null'),
  'TextBlockElement carries the paper field');
check(createBlock.includes('table.readTable(15)') &&
  createBlock.includes('decodeOriginalPaper') &&
  createBlock.includes('blockType !== OriginalBlockType.TEXT && payload.paper !== null') &&
  createBlock.includes("'create_text_paper'") &&
  createBlock.includes('cloneOriginalPaper'),
  'CreateBlock decodes/validates/persists/applies the paper register (TEXT-only)');
check(textRenderer.includes('element.paper === undefined ? null : element.paper'),
  'text renderer consumes element.paper');

// --- Harmony 边界（登记项）---
check(canvas.includes('element.paper = null'),
  'local text drafts seed paper=null (the determined default)');
check(!settingsStore.includes('textBoxPaper') && !settingsStore.includes('text_box_paper'),
  'no text_box_paper preference key — the setting row is absent');

console.log(`D05_ORIGINAL_TEXT_BOX_PAPER_FAIL_CLOSED_REPLAY_OK TOTAL=${total} FAILED=0`);
