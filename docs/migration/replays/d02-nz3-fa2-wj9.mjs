// Phase 960 — nz3 EnumEntries + fa2.w 日志 + wj9 元素提供器 + qub.l
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const nz3 = readFileSync(`${ROOT}/nz3.java`, 'utf8');
const fa2 = readFileSync(`${ROOT}/fa2.java`, 'utf8');
const wj9 = readFileSync(`${ROOT}/wj9.java`, 'utf8');
const qub = readFileSync(`${ROOT}/qub.java`, 'utf8');
const uq9 = readFileSync(`${ROOT}/uq9.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// nz3 = Kotlin EnumEntries
ok(/class nz3 extends y3 implements lz3, RandomAccess/.test(nz3), 'nz3 = EnumEntries impl');
ok(/public final Enum\[\] I;/.test(nz3), 'nz3.I = enum array');
ok(/x90\.f0\(r3\.ordinal\(\), this\.I\)\) == r3/.test(nz3), 'nz3.contains = ordinal lookup');
ok(/final int d\(\)[\s\S]{0,60}this\.I\.length/.test(nz3), 'nz3.d = size');

// uq9.m payloadType: byte -> ordinal, out-of-range -> entries[0]=NONE
ok(/\(b & 255\) - \(\(\(haa\) nz3Var\.get\(0\)\)\.I & 255\)/.test(uq9), 'uq9.m: byte rel first-ordinal');
ok(/i < 0 \|\| i >= nz3Var\.d\(\)[\s\S]{0,80}nz3Var\.get\(0\)/.test(uq9), 'uq9.m: out-of-range -> NONE fallback');

// fa2.w = negative-length logger
ok(/static void w\(Integer num, yn7 yn7Var, String str, Exception exc\)[\s\S]{0,80}a\.c\(yn7Var, str, exc, new lg5\(0, num\)\)/.test(fa2), 'fa2.w = a.c(yn7,str,exc,lg5(0,num))');

// wj9 element provider: case 9 = qub.l into pooled cxc
ok(/case 9:[\s\S]{0,100}\(\(qub\) obj2\)\.l\(\(\(Number\) obj\)\.intValue\(\), cxcVar\)/.test(wj9), 'wj9 case9 = qub.l(i, cxc)');
ok(/case 10:[\s\S]{0,100}\(\(f2c\) obj2\)\.l\(/.test(wj9), 'wj9 case10 = f2c.l same pattern');
ok(/case 7:[\s\S]{0,100}\(\(zgb\) obj2\)\.m\(uq9Var2/.test(wj9), 'wj9 case7 = zgb.m(uq9, i)');

// qub.l = zero-copy element accessor, 12B stride
ok(/public final void l\(int i, cxc cxcVar\)/.test(qub), 'qub.l = element accessor');
ok(/i \* 12\) \+ f\(iC\)/.test(qub), 'qub.l: element off = i*12 + f(slot)');
ok(/vector locations is empty/.test(qub), 'qub.l: empty -> h34.l out-of-range');
ok(/cxcVar\.b\(iF, byteBuffer\)/.test(qub), 'qub.l: cxc.b(off,bb) in-place init');
ok(/"RemoveChars\(locations=" \+ lv2\.N\(this\)/.test(qub), 'qub toString = RemoveChars + lv2.N');

console.log(`\nnz3-fa2-wj9 replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
