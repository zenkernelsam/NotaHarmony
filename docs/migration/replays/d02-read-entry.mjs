// Phase 978 — uhj.n 根读入口 + ic3 标志集
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const uhj = readFileSync(`${ROOT}/uhj.java`, 'utf8');
const ic3 = readFileSync(`${ROOT}/ic3.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// uhj.n = getRootAsX entry
ok(/static r29 n\(ByteBuffer byteBuffer\)/.test(uhj), 'uhj.n = r29 read entry');
ok(/byteBuffer\.order\(ByteOrder\.LITTLE_ENDIAN\)/.test(uhj), 'uhj.n: LITTLE_ENDIAN');
ok(/r29Var\.d\(byteBuffer\.position\(\) \+ byteBuffer\.getInt\(byteBuffer\.position\(\)\), byteBuffer\)/.test(uhj), 'uhj.n: d(pos+uoffset) root init');

// ic3 = 6-bit flag set
ok(/e = i2;[\s\S]{0,60}f = i3;[\s\S]{0,60}g = i4;[\s\S]{0,60}h = i5;[\s\S]{0,60}i = i6;[\s\S]{0,60}j = i7;/.test(ic3), 'ic3: e..j = shift flags 1,2,4,8,16,32');
ok(/k = i8/.test(ic3) && /\(i2 << 6\) - 1/.test(ic3), 'ic3: k = 6-bit mask 63');
ok(/l = i9/.test(ic3) && /i2 \| i3 \| i4/.test(ic3), 'ic3: l = combo flag');
ok(/ic3\.class\.getFields\(\)/.test(ic3) && /new hc3\(i10, name\)/.test(ic3), 'ic3: reflection flag registry -> hc3');

// uhj flag providers + helpers
ok(/static int l\(\) {[\s\S]{0,40}return ic3\.e/.test(uhj), 'uhj.l -> ic3.e');
ok(/static int q\(\) {[\s\S]{0,40}return ic3\.j/.test(uhj), 'uhj.q -> ic3.j');
ok(/i4 = i - i3;[\s\S]{0,40}i4 < 0 \? i4 \+ i2/.test(uhj), 'uhj.r: circular distance helper');
ok(/byte\[\] a\(byte\[\] bArr/.test(uhj) && /arraycopy/.test(uhj), 'uhj.a: array slice impl');

console.log(`\nread-entry replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
