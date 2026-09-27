// Phase 943 — 字符/组 op 偏移回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const e46 = rd('e46.java');
ok(e46.match(/cxc j\(\)[\s\S]{0,60}c\(4\)/), 'e46 location @c(4)');
ok(e46.match(/int l\(\)[\s\S]{0,60}c\(6\)/), 'e46 unicodeScalar @c(6)');
ok(e46.match(/qo5 k\(\)[\s\S]{0,60}c\(8\)/), 'e46 textField @c(8)');

const f46 = rd('f46.java');
ok(f46.match(/cxc j\(\)[\s\S]{0,60}c\(4\)/), 'f46 location @c(4)');
ok(f46.match(/String k\(\)[\s\S]{0,60}c\(6\)/), 'f46 string @c(6)');
ok(f46.match(/qo5 l\(\)[\s\S]{0,60}c\(8\)/), 'f46 textField @c(8)');

const pub = rd('pub.java');
ok(pub.match(/cxc j\(\)[\s\S]{0,60}c\(4\)/) && pub.match(/qo5 k\(\)[\s\S]{0,60}c\(6\)/),
  'pub = {location:cxc, textField:qo5}');

const qub = rd('qub.java');
ok(qub.match(/int j\(\)[\s\S]{0,60}c\(4\)/) && qub.match(/qo5 k\(\)[\s\S]{0,60}c\(6\)/),
  'qub = {locations:cxc[], textField:qo5}');

const f2c = rd('f2c.java');
ok(f2c.match(/int j\(\)[\s\S]{0,60}c\(4\)/) && f2c.match(/qo5 k\(\)[\s\S]{0,60}c\(6\)/),
  'f2c = {locations:cxc[], textField:qo5}');

const cm2 = rd('cm2.java');
ok(cm2.match(/c\(4\)/), 'cm2 members vector @c(4)');
ok(cm2.includes('Cannot create a group with 0 members'), 'cm2 zero-member validation');

const vd8 = rd('vd8.java');
ok(vd8.match(/qo5 j\(\)[\s\S]{0,80}c\(4\)/), 'vd8 group @c(4)');
ok(vd8.match(/int k\(\)[\s\S]{0,60}c\(6\)/), 'vd8 members vector @c(6)');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
