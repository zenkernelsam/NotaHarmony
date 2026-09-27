// Phase 876 — u5j 操作工厂签名登记回归
// 证据：docs/migration/evidence/phase-876-u5j-factory-signatures.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const U5J = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/u5j.java';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

const u5j = readFileSync(U5J, 'utf8');

// ---- 签名存在性（方法+返回类型） ----
const sigs = [
  ['A(x09 x09Var, qo5 qo5Var, z1d', 'me8 A', 'MODIFY_STYLE 13-arg'],
  ['pub D(x09 x09Var, cxc cxcVar, qo5 qo5Var)', 'pub D', 'REMOVE_CHAR {cxc,qo5}'],
  ['qub E(x09 x09Var, ArrayList arrayList, qo5 qo5Var)', 'qub E', 'REMOVE_CHARS {List,qo5}'],
  ['f2c G(qo5 qo5Var, x09 x09Var, List list)', 'f2c G', 'REVIVE_CHARS'],
  ['l2d H(x09 x09Var, z2d z2dVar, m2d m2dVar, z2d z2dVar2, Boolean bool, String str, Float f, tv6 tv6Var, dz0 dz0Var)',
    'l2d H', 'SET_METADATA 8 setter args'],
  ['mqf J(x09 x09Var, qo5 qo5Var, exc excVar, boolean z)', 'mqf J', 'UPDATE_CHECKBOX {qo5,exc,boolean}'],
  ['gd a(x09 x09Var, qo5 qo5Var, List list, List list2)', 'gd a', 'ADD_PATH_ELEMENTS'],
  ['rl2 f(x09 x09Var, cz0 cz0Var, cxc cxcVar, fqa fqaVar, qed qedVar, qed qedVar2, dp5 dp5Var, String str, hu1 hu1Var, int i)',
    'rl2 f', 'CREATE_BLOCK 9 args'],
  ['dm2 g(x09 x09Var, cxc cxcVar, fqa fqaVar, Float f, qed qedVar, u16 u16Var, t16 t16Var, ife ifeVar',
    'dm2 g', 'CREATE_INK opens with cxc/fqa/Float/qed/u16/t16/ife'],
  ['ln2 i(x09 x09Var, int i, int i2, int i3)', 'ln2 i', 'CREATE_PAGE 3 ints'],
  ['ao2 j(x09 x09Var, cxc cxcVar, fqa fqaVar, Float f, v4d v4dVar, u16 u16Var, t16 t16Var',
    'ao2 j', 'CREATE_SHAPE with v4d+u16+t16'],
  ['s83 k(x09 x09Var, List list, List list2, List list3, List list4)', 's83 k', 'DELETE_ENTITIES 4 lists'],
  ['td8 n(x09 x09Var, List list, ty0 ty0Var, cxc cxcVar, fqa fqaVar, k2d k2dVar, y2d y2dVar, qed qedVar, ive iveVar, Boolean bool, xgb xgbVar',
    'td8 n', 'MODIFY_BLOCK setter args'],
  ['wd8 q(x09 x09Var, ArrayList arrayList, hu1 hu1Var, Float f, t16 t16Var, int i)', 'wd8 q', 'MODIFY_INK simple'],
  ['wd8 r(x09 x09Var, List list, cxc cxcVar, fqa fqaVar, k2d k2dVar, y2d y2dVar, t16 t16Var, hu1 hu1Var, Float f, nl8 nl8Var',
    'wd8 r', 'MODIFY_INK full with nl8 setters'],
  ['ge8 s(x09 x09Var, List list, Integer num, m2d m2dVar, oz9 oz9Var, int i)', 'ge8 s', 'MODIFY_PAGE'],
  ['ge8 t(x09 x09Var, List list, lxc lxcVar, m2d m2dVar, oz9 oz9Var)', 'ge8 t', 'MODIFY_PAGE moveTo variant'],
  ['he8 u(x09 x09Var, exc excVar, exc excVar2, qo5 qo5Var, a3d a3dVar, o2d o2dVar, k2d k2dVar, j2d j2dVar, z2d z2dVar, b3d b3dVar)',
    'he8 u', 'PARAGRAPH_STYLE exc range pair'],
  ['je8 v(x09 x09Var, List list)', 'je8 v', 'MODIFY_POSITIONS single list'],
  ['ke8 w(x09 x09Var, qo5 qo5Var, String str, List list, xgb xgbVar)', 'ke8 w', 'MODIFY_RECORDING'],
  ['le8 x(x09 x09Var, List list, cxc cxcVar, fqa fqaVar, v4d v4dVar, t16 t16Var, hu1 hu1Var, Float f, g2d g2dVar, Boolean bool, int i)',
    'le8 x', 'MODIFY_SHAPE'],
  ['vd8 p(qo5 qo5Var, x09 x09Var, List list)', 'vd8 p', 'MODIFY_GROUP'],
];
for (const [needle, , label] of sigs) {
  ok(u5j.includes(needle), label);
}

// ---- 语义锚点 ----
ok((u5j.match(/exc excVar/g) || []).length >= 3, 'exc used as position arg type (J/u)');
ok((u5j.match(/xgb xgbVar/g) || []).length >= 5, 'xgb wall-clock in create/modify factories');
ok(u5j.includes('mmf mmfVar'), 'mmf ink ordinal only in CREATE_INK (g)');
ok(u5j.includes('v4d v4dVar'), 'v4d shape-kind in j/x factories');
ok(u5j.includes('nl8 nl8Var'), 'nl8 nullable setter triple in r()');
ok(u5j.includes('a3d a3dVar') && u5j.includes('b3d b3dVar') && u5j.includes('j2d j2dVar') &&
   u5j.includes('o2d o2dVar'), 'paragraph-style setter types in u()');
ok(u5j.includes('z66 z66Var'), 'z66 style-setter in A()');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
