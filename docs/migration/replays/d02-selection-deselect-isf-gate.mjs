// Phase 1439 — 选区种类门控：DESELECT 仅 isf 型选区装配
// 原版证据（decompiled_1.4.2）：
//   m36/urf 菜单装配器：wqf 枚举 23 项；DESELECT 仅当选区为 isf 时出现。
//   ch1.java:155 单实体点选 → lsf；ch1.java:178 组点选 → jsf；
//   hmb.i(t87) 通用单实体选择 → lsf；hsf=进行中套索（j01 "in-progress lasso"），
//   完成经 z6c 转 isf；j01:65-87 粘贴按既有选区种类保种（isf→isf /
//   lsf→new lsf / jsf→new jsf / hsf→拒绝并 warn）。
// Harmony 移植：SelectionState.supportsDeselectMode 来源标记 +
//   selectElementIds 可选 drawnKind（false=点选型，true=集合型，
//   undefined=保种）+ SelectionOverlay canDeselect 门控行 +
//   enterDeselectMode 同判兜底。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');

const tool = read('note/src/main/ets/rendering/SelectionTool.ets');
const overlay = read('note/src/main/ets/ui/components/SelectionOverlay.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 1) SelectionTool 来源标记 ---
check(/supportsDeselectMode:\s*boolean/.test(tool),
  'SelectionState carries supportsDeselectMode kind marker');
check(/supportsDeselectMode:\s*false/.test(tool),
  'constructor initialises marker to false (no-selection default)');
check(tool.includes('this.state.supportsDeselectMode = false;\n    this.state.transform'),
  'beginSelection resets marker alongside transform');

// --- 2) finalizeSelection：hsf→isf 转换点 ---
check(/supportsDeselectMode = total > 0/.test(tool),
  'finalizeSelection marks isf only on non-empty drawn hit (empty lasso drops)');

// --- 3) selectElementIds 三态 drawnKind ---
check(/drawnKind\?:\s*boolean/.test(tool),
  'selectElementIds accepts optional drawnKind marker');
check(/drawnKind !== undefined/.test(tool) &&
  /if \(!this\.state\.isActive\)/.test(tool),
  'undefined preserves kind; empty result always clears marker');
check(/deselect\(\)[\s\S]*?supportsDeselectMode = false/.test(tool),
  'deselect() resets marker');
check(/enterDeselectMode[\s\S]*?!this\.state\.supportsDeselectMode/.test(tool),
  'enterDeselectMode defensively refuses lsf/jsf kinds');

// --- 4) NoteCanvasView 调用点分类 ---
check(/applyTapSelect[\s\S]*?resolved\.groupIds,\s*\n[\s\S]*?\.id\),\s*\n\s*false\)/.test(canvas),
  'tap-select (lsf/jsf families) passes drawnKind=false');
check(/selectAllPageElements[\s\S]*?\.id\),\s*\n\s*true\)/.test(canvas),
  'select-all (ftc-equivalent collection) passes drawnKind=true');
check(/selectElementIds\(strokeIds, shapeIds, textIds, imageIds, \[\], mathIds,\s*\n\s*true\)/.test(canvas),
  'select-all-delete funnel marked collection kind');
check(/finalImages\.length > 1/.test(canvas),
  'image insert: preserve over existing selection; fresh multi→isf, single→lsf');
check(/\[result\.math\.id\],\s*\n\s*this\.selectionVisible \? undefined : false/.test(canvas),
  'math insert: fresh single-entity select → lsf kind');
check((canvas.match(/this\.selectionVisible \? undefined : true/g) || []).length >= 2,
  'both paste paths preserve existing kind, fresh paste → isf (j01 65-87)');
// crop re-assert paths must NOT pass drawnKind (kind survives modal flow)
check(/selectElementIds\(\[\], \[\], \[\], \[imageId\]\)/.test(canvas) &&
  /selectElementIds\(\[\], \[\], \[\], \[after\.id\]\)/.test(canvas),
  'crop cancel/confirm re-asserts preserve selection kind');

// --- 5) Overlay 门控 ---
check(/@Prop canDeselect:\s*boolean/.test(overlay),
  'SelectionOverlay exposes canDeselect prop');
check(/if \(this\.canDeselect\)[\s\S]*?SelectionMenuAction\.DESELECT/.test(overlay),
  'DESELECT menu row assembled only when canDeselect (urf isf-only)');

// --- 6) NoteCanvasView 镜像 + 绑定 ---
check(/@State selectionCanDeselect:\s*boolean = false/.test(canvas) &&
  /this\.selectionCanDeselect = state\.supportsDeselectMode/.test(canvas) &&
  /canDeselect: this\.selectionCanDeselect/.test(canvas),
  'selectionCanDeselect mirrors tool state into overlay prop');

// --- 7) 文档闭环 ---
assert.ok(read('docs/migration/evidence/phase-1439-selection-deselect-gate.md').length > 0,
  'evidence doc exists');
assert.ok(read('docs/migration/adr/ADR-1374-selection-deselect-gate.md').includes('isf'),
  'ADR-1374 records isf-only deselect adjudication');

console.log(`selection deselect isf-gate: ${total}/18 checks green`);
