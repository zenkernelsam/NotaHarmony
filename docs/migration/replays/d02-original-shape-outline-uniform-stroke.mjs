// D02 原版 1.4.2 SHAPE 描边 = px5.a Standard 均匀宽（证据纠错）
// Phase 1426：修正 ADR-1361 的误判——psi(SHAPE 状态) 无 aj1 字段，
// cc3.H() 给 eti.T(SHAPE) 的 zsi.h=null，lnc.u() 因此走
// k9m.b() 的 px5 支 = jmc.c(均匀宽路径)，与 Harmony strokeShape
// 的固定 setLineWidth 完全对齐——不存在"描边凿尖缺口"。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};
const read = p => fs.readFileSync(p, 'utf8');

const renderer = read('note/src/main/ets/rendering/ShapeCanvasRenderer.ets');
const vm = read('note/src/main/ets/ui/editor/EditorViewModel.ets');
const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
const brushTypes = read('note/src/main/ets/core/model/BrushTypes.ets');

// --- 原版语义对齐：SHAPE 描边 = 均匀宽圆头 ---
const strokeShape = renderer.indexOf('private strokeShape');
check('strokeShape strokes with uniform strokeWidth (px5.a/jmc.c parity)',
  /ctx\.setLineWidth\(shape\.strokeWidth\)/.test(renderer) &&
  /ctx\.setLineJoin\(shape\.originalStyle === 3 \? 'miter' : 'round'\)/.test(renderer));
check('strokeShape does NOT use nib outline builder (无 ox5 变宽)',
  !renderer.includes('WidthOutlineBuilder') &&
  !renderer.includes('nibAngle') && !renderer.includes('nibFlatness'));
check('dash/dot styles still map to so7 DASH/DOTS on uniform width',
  renderer.indexOf('setLineDash([2 * shape.strokeWidth') > strokeShape &&
  renderer.indexOf('setLineDash([0.001 * shape.strokeWidth') > strokeShape);

// --- SHAPE 工具无 nib 状态（psi 无 aj1） ---
check('ToolState nib fields documented CALLIGRAPHY-only (eti.G)',
  brushTypes.includes('仅 CALLIGRAPHY 工具使用'));
check('renderSpec nib only for CALLIGRAPHY (其余工具 null)',
  /nibAngle: this\.currentTool === ToolType\.CALLIGRAPHY/.test(vm));
check('nib setters gated on isCalligraphyActive, no shape-nib setter',
  (vm.match(/isCalligraphyActive\(\)/g) || []).length >= 3 &&
  !/setShapeNib|shapeNibAngle|shapeNibFlatness/.test(vm));
check('shape strip branch exposes no nib panel (iw4 case8 = 纯种类行)',
  !toolbar.slice(toolbar.indexOf('isShapeActive())')).includes('CalligraphyNibPanel'));

// --- 文档纠错已落地 ---
const adr = read('docs/migration/adr/ADR-1361-shape-strip-kind-picker.md');
const ev = read('docs/migration/evidence/phase-1425-shape-strip-kind-picker.md');
check('ADR-1361 corrected: px5.a uniform-stroke parity stated',
  adr.includes('px5.a') && adr.includes('psi') && !adr.includes('ShapeCanvasRenderer 仍用固定线宽'));
check('phase-1425 evidence corrected: no remaining nib gap',
  ev.includes('px5.a') && !ev.includes('剩余边界'));

console.log(`TOTAL=${checks.length} FAILED=0`);
