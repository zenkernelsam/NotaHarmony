// Phase 957 — nti 线协议助手：cxc 工厂对 + n0/o0 LEB128 + iy0 预读
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const nti = readFileSync(`${ROOT}/nti.java`, 'utf8');
const iy0 = readFileSync(`${ROOT}/iy0.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// nti.X = cxc 12B writer (= sg5.f byte-exact)
ok(/static final int X\(cxc cxcVar, a aVar\)/.test(nti), 'X = cxc writer');
ok(/aVar\.t\(4, 12\);\s*aVar\.w\(iC\);\s*aVar\.w\(iD\);\s*aVar\.s\(2\);\s*aVar\.y\(sC\)/.test(nti), 'X: t(4,12) w(idx) w(ts) s(2) y(site)');

// nti.f = cxc factory (site,timestamp,index)
ok(/static cxc f\(short s, int i, int i2\)/.test(nti), 'f = cxc factory');
ok(/aVarA\.t\(4, 12\);\s*aVarA\.w\(i2\);\s*aVarA\.w\(i\);\s*aVarA\.s\(2\);\s*aVarA\.y\(s\)/.test(nti), 'f: same reverse-write');
ok(/cxcVar\.b\(byteBufferWrap/.test(nti) && /ybg\.c\(cxcVar\)/.test(nti) && /rh8\.q\(c8dVar/.test(nti), 'f: re-read + validate + close');

// nti.g = Id -> SeqId derivation
ok(/static final cxc g\(qo5 qo5Var, int i\)[\s\S]{0,150}return f\(qo5Var\.c\(\), qo5Var\.d\(\), i\)/.test(nti), 'g: cxc = f(qo5.site, qo5.ts, index)');

// nti.n0 = u32 LEB128
ok(/static void n0\(ByteArrayOutputStream byteArrayOutputStream, int i\)/.test(nti), 'n0 = varint writer');
ok(/i >= 128[\s\S]{0,80}128 \| \(i & 127\)[\s\S]{0,80}i >>>= 7/.test(nti), 'n0: LEB128 7-bit loop');
ok(/o14\.r\("Failed requirement\."\)/.test(nti), 'n0: negative -> require fail');

// nti.o0 = i32 zigzag-LEB128
ok(/\(j >> 31\) \^ \(j << 1\)[\s\S]{0,60}& 4294967295L/.test(nti), 'o0: zigzag (i>>31)^(i<<1)');
ok(/128 \| \(127 & j2\)[\s\S]{0,80}j2 >>>= 7/.test(nti), 'o0: varint loop on zigzag');

// nti.p = range check
ok(/is out of range of \[" \+ i2 \+ ", " \+ i3 \+ "\] \(too low\)/.test(nti), 'p: range check too low/high');

// iy0 = bk_paths appender (uses varints)
ok(/nti\.n0\(y64Var, list\.size\(\)\)/.test(iy0), 'iy0: varint path count');
ok(/nti\.o0\(y64Var, iY0 - i14\)/.test(iy0) && /nti\.o0\(y64Var, iY1 - i15\)/.test(iy0), 'iy0: zigzag delta coords');
ok(/m18\.y0\(Float\.intBitsToFloat/.test(iy0), 'iy0: fixed-point quantize m18.y0');
ok(/4096\.0f/.test(iy0), 'iy0: x4096 quantization scale');
ok(/bk_paths\.append blob exceeds cap/.test(iy0) && /1048576/.test(iy0), 'iy0: 1MiB blob cap');
ok(/zeb\.e\(this\.n, s, i, i2, j2/.test(iy0) && /crc32\.getValue\(\)/.test(iy0), 'iy0: zeb.e index header + CRC32');
ok(/FileChannel\.MapMode\.READ_ONLY/.test(iy0), 'iy0.f = mmap read-only');

console.log(`\nnti-wire-helpers replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
