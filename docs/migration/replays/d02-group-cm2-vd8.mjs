// Phase 914 — cm2=CreateGroup / vd8=ModifyGroup 读图回归
// 证据：docs/migration/evidence/phase-914-group-cm2-vd8.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const cm2 = rd('cm2.java');
const vd8 = rd('vd8.java');
const zq9 = rd('zq9.java');

ok(cm2.includes('CreateGroup(members='), 'cm2 = CreateGroup');
ok(cm2.includes('Cannot create a group with 0 members'), 'cm2 zero-member guard');
ok(cm2.match(/void j\(qo5 qo5Var, int i\)[\s\S]{0,160}c\(4\)/), 'cm2 j -> c(4) members');
ok(cm2.includes('(i * 8) + f(iC)'), 'qo5 8B inline-struct vector addressing');
ok(cm2.includes('lv2.P(this)'), 'lv2.P members materializer');

ok(vd8.includes('ModifyGroup(group='), 'vd8 = ModifyGroup');
ok(vd8.match(/qo5 j\(\)[\s\S]{0,200}c\(4\)/), 'vd8 j -> c(4) group');
ok(vd8.includes('No value for (required) field group'), 'group required');
ok(vd8.match(/int k\(\)[\s\S]{0,120}c\(6\)/), 'vd8 k -> c(6) members len');
ok(vd8.match(/void l\(qo5 qo5Var, int i\)[\s\S]{0,160}c\(6\)/), 'vd8 l -> c(6) members');
ok(vd8.includes('lv2.Q(this)'), 'lv2.Q members materializer');

ok(zq9.includes('cm2.class') && zq9.includes('haa.CREATE_GROUP'), 'cm2 -> CREATE_GROUP');
ok(zq9.includes('vd8.class') && zq9.includes('haa.MODIFY_GROUP'), 'vd8 -> MODIFY_GROUP');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
