// Phase 956 — cee/xwd 读侧原语 + x82 UTF-8 解码助手
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const cee = readFileSync(`${ROOT}/cee.java`, 'utf8');
const xwd = readFileSync(`${ROOT}/xwd.java`, 'utf8');
const x82 = readFileSync(`${ROOT}/x82.java`, 'utf8');
const zq6 = readFileSync(`${ROOT}/zq6.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// xwd — bare inline-struct base
ok(/public abstract class xwd/.test(xwd), 'xwd = inline-struct base');
ok(/public int I;[\s\S]{0,60}public ByteBuffer J;/.test(xwd), 'xwd = {I pos, J bb} only');
ok(/void b\(int i, ByteBuffer byteBuffer\)/.test(xwd), 'xwd.b = init');

// cee — table reader base
ok(/public abstract class cee/.test(cee), 'cee = table base');
ok(/public int I;[\s\S]{0,200}public ByteBuffer J;[\s\S]{0,200}public int K;[\s\S]{0,200}public int L;/.test(cee), 'cee = {I,K=vtableOff,L=vtableLen,J}');
ok(/final zq6 M = zq6\.i\(\)/.test(cee), 'cee.M = zq6 instance');

// d() init: vtable at negative relative offset
ok(/this\.K = i2;[\s\S]{0,60}this\.L = this\.J\.getShort\(i2\)/.test(cee) && /i - byteBuffer\.getInt\(i\)/.test(cee), 'd: K=i-getInt(i), L=getShort(K)');

// c() vtable slot: i<L -> getShort(K+i), else 0
ok(/public final int c\(int i\)[\s\S]{0,120}i < this\.L[\s\S]{0,100}getShort\(this\.K \+ i\)[\s\S]{0,80}return 0/.test(cee), 'c: i<L -> getShort(K+i) else 0');

// b() indirect
ok(/public final int b\(int i\)[\s\S]{0,60}getInt\(i\) \+ i/.test(cee), 'b: uoffset = getInt(i)+i');

// e() UTF-8: ASCII fast path + x82 helpers + bounds/errors
ok(/b < 0\)[\s\S]{0,60}break/.test(cee), 'e: ASCII fast-path until high byte');
ok(/b2 < -32[\s\S]{0,400}x82\.A\(/.test(cee), 'e: 2-byte via x82.A');
ok(/b2 < -16[\s\S]{0,400}x82\.z\(/.test(cee), 'e: 3-byte via x82.z');
ok(/x82\.y\(b2, b4, b5/.test(cee), 'e: 4-byte via x82.y (surrogate pair)');
ok(/o14\.r\("Invalid UTF-8"\)/.test(cee), 'e: malformed -> Invalid UTF-8');
ok(/s5c\.q\("buffer limit=%d/.test(cee), 'e: bounds s5c.q guard');

// f/i vector start/length; g byte-slice
ok(/getInt\(i2\) \+ i2 \+ 4/.test(cee), 'f: vector data = indirect+4');
ok(/public final int i\(int i\)[\s\S]{0,100}getInt\(this\.J\.getInt/.test(cee), 'i: vector length via indirect');
ok(/duplicate\(\)\.order\(ByteOrder\.LITTLE_ENDIAN\)/.test(cee) && /byteBufferOrder\.position\(iF\)/.test(cee), 'g: zero-copy LE slice');

// x82 UTF-8 trio
ok(/static void A\(byte b2, byte b3, char\[\]/.test(x82), 'x82.A = 2-byte decode');
ok(/static void z\(byte b2, byte b3, byte b4, char\[\]/.test(x82), 'x82.z = 3-byte decode');
ok(/static void y\(byte b2, byte b3, byte b4, byte b5, char\[\]/.test(x82), 'x82.y = 4-byte decode');

// zq6 = merged multi-role
ok(/implements we4, xh2, go2/.test(zq6), 'zq6 = R8-merged multi-role');

console.log(`\ncee-xwd-primitives replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
