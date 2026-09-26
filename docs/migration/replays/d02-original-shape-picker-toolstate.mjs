// D02 原版 1.4.2 形状选择器与工具状态列 — Phase 776
// 钉住六形状键族（1.0.3 缺席）、ToolStateEntity 三列增量与 1.0.3 的 shapeKind 参数史。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const s142 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/strings.xml', 'utf8');
const s103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
const src = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const kinds = ['shape_rectangle', 'shape_ellipse', 'shape_triangle', 'shape_diamond', 'shape_line', 'shape_arrow'];
check('1.4.2 ships six explicit shape-kind keys',
  kinds.every((k) => s142.includes(`ui_tools__${k}">`)));
check('1.0.3 had no ui_tools__shape_* picker keys',
  !kinds.some((k) => s103.includes(`ui_tools__${k}`)));
check('1.0.3 CreateShape already carried a shapeKind param (detection-side, no picker)',
  fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/kj.java', 'utf8')
    .includes('shapeKind='));

const toolstate = fs.readFileSync(`${src}/defpackage/ca3.java`, 'utf8')
  + fs.readFileSync(`${src}/defpackage/zmb.java`, 'utf8');
check('ToolStateEntity persists shapeKind with RECTANGLE default',
  toolstate.includes("`shapeKind` TEXT DEFAULT 'RECTANGLE'"));
check('ToolStateEntity persists googleInkBrushPackId + penLastStandardColorWellIndex',
  toolstate.includes('`googleInkBrushPackId` INTEGER DEFAULT NULL')
  && toolstate.includes('`penLastStandardColorWellIndex` INTEGER DEFAULT NULL'));
check('ToolStateEntity_new migration adds tray FK cascade + freehand/partial columns',
  toolstate.includes('FOREIGN KEY(`tray_owner_id`) REFERENCES `TrayEntity`(`tray_id`)')
  && toolstate.includes('`selectionIsFreehand`') && toolstate.includes('`eraserIsPartial`'));

console.log(`shape picker + toolstate replay: ${checks.length}/${checks.length} checks green`);
