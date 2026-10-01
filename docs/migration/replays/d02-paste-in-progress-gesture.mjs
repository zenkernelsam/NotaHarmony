// Phase 1443 — 进行中套索手势上的粘贴不产选区（j01 hsf→null 支对齐）
// 原版证据（decompiled_1.4.2 j01.java:59-90）：
//   粘贴结果选区按既有 msf 保种——isf→isf（lb8.e 重装配）、lsf→new lsf、
//   jsf→new jsf、hsf→log "Paste attempted on in-progress lasso selection"
//   并 return null：内容照插但**不产选区结果**（进行中手势态保持，
//   其后 finalize 自决）。
// Harmony：新增 SelectionTool.isSelectionGestureInProgress()
//   = isActive && 六类 id 全空（beginSelection 已置、finalize 未决）；
//   两处粘贴点（组图粘贴 applyOriginalGroupClipboardPaste 回调 +
//   commitOriginalClipboardPaste 完成支）以此为门跳过 selectElementIds。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');

const tool = read('note/src/main/ets/rendering/SelectionTool.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 1) 谓词实现：isActive + 六类 id 全空 ---
check(/isSelectionGestureInProgress\(\): boolean \{\s*\n\s*return this\.state\.isActive &&\s*\n\s*this\.state\.selectedStrokeIds\.length === 0 &&[\s\S]*?selectedMathIds\.length === 0;\s*\n\s*\}/
  .test(tool),
  'isSelectionGestureInProgress = isActive && 六类 id 全空');
check(tool.indexOf('isSelectionGestureInProgress') <
  tool.indexOf('drawnBounds()'),
  '谓词位于 drawnBounds 之前（SelectionTool 选区区）');
check(tool.includes('j01 hsf 支谓词') && tool.includes('不产选区结果'),
  '谓词注释记录 j01 hsf→null 证据');

// --- 2) 两处粘贴点均以谓词为门 ---
const gateSites = canvas.match(/if \(!this\.selectionTool\.isSelectionGestureInProgress\(\)\) \{\s*\n\s*this\.selectionTool\.selectElementIds\(/g);
check(gateSites !== null && gateSites.length === 2,
  `两处粘贴选区断言以 isSelectionGestureInProgress 为门（${gateSites ? gateSites.length : 0}/2）`);

// 组图粘贴回调内
const groupIdx = canvas.indexOf('applyOriginalGroupClipboardPaste');
const groupSlice = canvas.slice(groupIdx, groupIdx + 9000);
check(groupSlice.includes('isSelectionGestureInProgress'),
  'applyOriginalGroupClipboardPaste 回调含进行中手势门');
// 标准粘贴完成支内（pastedIds 形参集）
check(/if \(!this\.selectionTool\.isSelectionGestureInProgress\(\)\) \{\s*\n\s*this\.selectionTool\.selectElementIds\(\s*\n\s*pastedIds, pastedShapeIds, pastedTextIds, pastedImageIds/
  .test(canvas),
  '标准粘贴完成支含进行中手势门（pastedIds 集）');

// --- 3) 门内仍传 selectionVisible 保种语义（j01 非 hsf 支不变） ---
check(canvas.match(/selectionVisible \? undefined : true/g)?.length >= 2,
  '粘贴点 selectionVisible?undefined:true 保种语义保留');

// --- 4) 谓词不误伤正常路径：isActive 双义复核 ---
// finalizeSelection 空命中也应保持 isActive 一致语义（谓词仅门粘贴断言）
check(tool.includes('this.state.isActive = true'),
  'beginSelection 置 isActive 保留');
check(/deselect\(\): void \{\s*\n\s*this\.state\.isActive = false;/.test(tool),
  'deselect 复位 isActive 保留');

console.log(`PHASE1443_PASTE_GESTURE_OK TOTAL=${total} FAILED=0`);
