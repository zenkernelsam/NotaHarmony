// D02 原版 1.4.2 SHAPE 次级条种类选择（iw4 case8 → qri.a + h5g.a/c）
// Phase 1425：折叠态=当前种类 48×48 图标钮（h5g.c，点击发 jri 展开）；
// 展开态=h5g.a 六类图标行（h5g.b 单元格：accent 底+描边选中、
// ui_tools__shape_* a11y）。Harmony 此前种类选择仅存在于
// ToolboxSettingsDialog（编辑器内无 in-strip 切换）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};
const read = p => fs.readFileSync(p, 'utf8');

const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
const picker = read('note/src/main/ets/ui/editor/ShapeKindPicker.ets');
const vm = read('note/src/main/ets/ui/editor/EditorViewModel.ets');
const strings = read('note/src/main/resources/base/element/string.json');

// --- 次级条分支 ---
const shapeBranch = toolbar.indexOf('isShapeActive())');
check('shape strip branch follows calligraphy, precedes style row',
  shapeBranch > toolbar.indexOf('isCalligraphyActive()') &&
  shapeBranch < toolbar.indexOf('supportsBrushStyleControls()'));

// --- 折叠/展开两态 ---
check('collapsed state renders single current-kind swatch',
  /shapeKindExpandedFor === this\.viewModel\.activeShapeToolId\(\)/.test(toolbar) &&
  toolbar.indexOf('kind: this.viewModel.activeShapeKind') > shapeBranch);
check('expand tap stores active shape tool id (jri 会话复位)',
  /this\.shapeKindExpandedFor = this\.viewModel\.activeShapeToolId\(\)/.test(toolbar));
check('expansion keyed per tool id (切换即折叠)',
  /@State shapeKindExpandedFor: string/.test(toolbar));
check('expanded state iterates all six kinds in r5g order',
  /ForEach\(SHAPE_KIND_ORDER/.test(toolbar));

// --- 单元格契约（h5g.b） ---
check('compact swatch is icon-only (无文字标签)', /compact \? 0 : 4\)/.test(picker) ||
  picker.includes('compact ? 36 : 56'));
check('compact swatch keeps shape_* a11y label',
  picker.includes('accessibilityText(shapeKindLabel(this.kind))'));
check('swatch selected gets accent border', picker.includes('this.selected ? this.accent'));
check('six kind labels exist', ['shape_rectangle', 'shape_ellipse', 'shape_diamond',
  'shape_triangle', 'shape_arrow', 'shape_line'].every(k => strings.includes(`"name": "${k}"`) ||
  strings.includes(`"name":"${k}"`)));

// --- 写回路径 ---
check('pick writes via setActiveShapeKind → setToolShapeKind',
  /setActiveShapeKind\(kind\)/.test(toolbar) &&
  /setActiveShapeKind\(kind: ShapeKind\)/.test(vm) &&
  /setToolShapeKind\(toolId, kind\)/.test(vm));
check('activeShapeToolId resolves active SHAPE row, never throws',
  /findFirstType\(this\.states, ToolType\.SHAPE\)/.test(vm) &&
  /toolId\.length === 0/.test(vm));
check('picker path unchanged (dialog still uses setToolShapeKind)',
  picker.includes('setToolShapeKind(tool.toolId, kind)'));
check('photoImportLeaseActive gates pick and expand',
  (toolbar.match(/photoImportLeaseActive/g) || []).length >= 2 &&
  toolbar.indexOf('photoImportLeaseActive', shapeBranch) > shapeBranch);

console.log(`TOTAL=${checks.length} FAILED=0`);
