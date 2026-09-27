// Phase 879 — 余子表实名登记回归（akb/dp5/qqe/z1d/m2d/lxc）
// 证据：docs/migration/evidence/phase-879-subtable-registry.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

// ---- 六表实名（toString） ----
const named = [
  ['akb.java', 'RecordingAsset(metadata=', 'akb = RecordingAsset'],
  ['dp5.java', 'ImageAsset(metadata=', 'dp5 = ImageAsset'],
  ['qqe.java', 'TextSelection(anchor=', 'qqe = TextSelection'],
  ['z1d.java', 'SetBool(value=', 'z1d = SetBool'],
  ['m2d.java', 'SetPageBackground(value=', 'm2d = SetPageBackground'],
  ['lxc.java', 'SeqMove(toId=', 'lxc = SeqMove'],
];
for (const [f, needle, label] of named) ok(rd(f).includes(needle), label);

// ---- 字段访问器类型 ----
ok(/public final wa0 j\(\)/.test(rd('akb.java')), 'akb.j() -> wa0 metadata');
const dp5 = rd('dp5.java');
ok(/public final wa0 j\(\)/.test(dp5) && /public final qed k\(\)/.test(dp5),
  'dp5 fields wa0+qed');
const qqe = rd('qqe.java');
ok(/public final cxc k\(\)/.test(qqe) && /public final cxc l\(\)/.test(qqe),
  'qqe fields cxc anchor + cxc focus');
ok(/public final Boolean j\(\)/.test(rd('z1d.java')), 'z1d.j() -> Boolean');
ok(/public final nz9 j\(\)/.test(rd('m2d.java')), 'm2d.j() -> nz9');
ok(/public final cxc j\(\)/.test(rd('lxc.java')), 'lxc.j() -> cxc toId');

// ---- extends cee implements ka4 ----
for (const f of ['akb', 'dp5', 'qqe', 'z1d', 'm2d', 'lxc']) {
  ok(rd(f + '.java').includes('extends cee implements ka4'), `${f} cee+ka4`);
}

// ---- 使用点锚点 ----
const u5j = rd('u5j.java');
ok(u5j.includes('egh.a(cxcVarB != null ? cxcVarB : null)'),
  'u5j.s moveToIndex -> cxc -> egh.a (lxc)');
ok(rd('egh.java').includes('lxc'), 'egh.a produces lxc');
ok(/m2d m2dVar/.test(u5j), 'u5j.s/n carry m2d SetPageBackground');
ok(rd('ge8.java').includes('m2d') && rd('ge8.java').includes('lxc'),
  'ge8 holds m2d + lxc fields');
ok(rd('me8.java').includes('z1dVarV = v()') && rd('me8.java').includes('z1dVarU = u()'),
  'me8 MODIFY_STYLE uses z1d setters');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
