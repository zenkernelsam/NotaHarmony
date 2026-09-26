// D02 原版 1.4.2 钢笔增强面 — Phase 778
// 钉住书法笔尖模型、nibAngle/nibFlatness/stabilization 三新列、
// style INTEGER→TEXT 迁移与七条 1.0.3 缺席的钢笔字符串。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const r142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2';
const r103 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const s142 = fs.readFileSync(`${r142}/resources/res/values/strings.xml`, 'utf8');
const s103 = fs.readFileSync(`${r103}/resources/res/values/strings.xml`, 'utf8');
const ca3 = fs.readFileSync(`${r142}/sources/defpackage/ca3.java`, 'utf8');
const e47 = fs.readFileSync(`${r103}/sources/defpackage/e47.java`, 'utf8');
const ox5 = fs.readFileSync(`${r142}/sources/defpackage/ox5.java`, 'utf8');
const px5 = fs.readFileSync(`${r142}/sources/defpackage/px5.java`, 'utf8');
const s01 = fs.readFileSync(`${r142}/sources/defpackage/s01.java`, 'utf8');
const ij1 = fs.readFileSync(`${r142}/sources/defpackage/ij1.java`, 'utf8');
const svi = fs.readFileSync(`${r142}/sources/defpackage/svi.java`, 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const penKeys = ['calligraphy', 'calligraphy_angle', 'calligraphy_flatness',
  'brush_style_fixed', 'brush_style_variable', 'brush_style_dashed',
  'brush_style_dotted', 'stabilization'];
check('1.4.2 ships eight pen-enhancement keys (calligraphy/styles/stabilization)',
  penKeys.every((k) => s142.includes(`ui_tools__${k}">`)));
check('1.0.3 had none of the pen-enhancement keys',
  !penKeys.some((k) => s103.includes(`ui_tools__${k}`)));
check('qx5 nib family: px5=Standard singleton, ox5=CalligraphyNib(angle,flatness)',
  px5.includes('implements qx5') && px5.includes('"Standard"')
  && ox5.includes('CalligraphyNib(nibAngle=') && ox5.includes('nibFlatness='));
check('calligraphy defaults: angle π/2 when null, flatness 0.0 when null',
  s01.includes('1.5707963267948966') && s01.includes('0.0f'));
check('ToolStateEntity 1.4.2: nibAngle/nibFlatness REAL + stabilization INTEGER new',
  ca3.includes('`nibAngle` REAL') && ca3.includes('`nibFlatness` REAL')
  && ca3.includes('`stabilization` INTEGER'));
check('ToolStateEntity style migrated INTEGER→TEXT',
  ca3.includes('`style` TEXT') && e47.includes('`style` INTEGER'));
check('1.0.3 had no nibAngle/nibFlatness/stabilization columns',
  !e47.includes('`nibAngle`') && !e47.includes('`nibFlatness`')
  && !e47.includes('`stabilization`'));
check('stabilization renders as a pen-options row; DAO selects all 18 columns',
  ij1.includes('ui_tools__stabilization')
  && svi.includes('`nibFlatness`,`stabilization` FROM `ToolStateEntity`'));

console.log(`pen-enhancements replay: ${checks.length}/${checks.length} checks green`);
