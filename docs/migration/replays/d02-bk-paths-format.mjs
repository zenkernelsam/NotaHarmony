// Phase 958 — bk_paths 磁盘格式：iy0 append + zeb.e 24B BE 索引 + zx0 文件对
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const iy0 = readFileSync(`${ROOT}/iy0.java`, 'utf8');
const zeb = readFileSync(`${ROOT}/zeb.java`, 'utf8');
const zx0 = readFileSync(`${ROOT}/zx0.java`, 'utf8');
const gy0 = readFileSync(`${ROOT}/gy0.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// 文件布局 bk_paths/<noteId>/<pageId>.{dat,idx}
ok(/new File\(\(File\) value, "bk_paths"\)/.test(zx0), 'zx0: bk_paths dir');
ok(/ldj\.r2\(cxcVar\)\.concat\("\.dat"\)/.test(zx0), 'zx0.a = <pageId>.dat');
ok(/ldj\.r2\(cxcVar\)\.concat\("\.idx"\)/.test(zx0), 'zx0.d = <pageId>.idx');
ok(/new File\(c\(\), ttfVar\.toString\(\)\)/.test(zx0), 'zx0.e = per-note dir');

// zeb.e 24B BE index header
ok(/bArr\[0\] = \(byte\) \(i4 >>> 8\);\s*bArr\[1\] = \(byte\) i4;\s*bArr\[2\] = 0;\s*bArr\[3\] = 0;/.test(zeb), 'zeb.e: site u16 BE + zero pad @0-3');
ok(/bArr\[4\] = \(byte\) \(i >>> 24\)/.test(zeb) && /bArr\[7\] = \(byte\) i;/.test(zeb), 'zeb.e: i int BE @4-7');
ok(/bArr\[8\] = \(byte\) \(i2 >>> 24\)/.test(zeb) && /bArr\[11\] = \(byte\) i2;/.test(zeb), 'zeb.e: i2 int BE @8-11');
ok(/bArr\[12\] = \(byte\) \(j >>> 56\)/.test(zeb) && /bArr\[19\] = \(byte\) j;/.test(zeb), 'zeb.e: j long BE @12-19 (offset)');
ok(/bArr\[20\] = \(byte\) \(i3 >>> 24\)/.test(zeb) && /bArr\[23\] = \(byte\) i3;/.test(zeb), 'zeb.e: crc32 int BE @20-23');

// iy0.a write path
ok(/long j2 = gy0Var\.b;[\s\S]{0,200}bk_paths\.append offset exceeds Int/.test(iy0), 'append: offset>Int32 guard');
ok(/nti\.n0\(y64Var, list\.size\(\)\)/.test(iy0), 'append: varint path count');
ok(/\(l8aVar\.b\.f\(i5\) & 3\) << i7/.test(iy0) && /i9 == 8/.test(iy0), 'append: 2-bit flag packing 4/byte');
ok(/byteBuffer\.getLong\(i17 \* 8\)/.test(iy0), 'append: idd long-packed points');
ok(/intBitsToFloat\(\(int\) \(j >> 32\)\) \* 4096\.0f/.test(iy0), 'append: x = f32hi * 4096');
ok(/intBitsToFloat\(\(int\) \(j & 4294967295L\)\) \* 4096\.0f/.test(iy0), 'append: y = f32lo * 4096');
ok(/j6 > 1048576/.test(iy0) && /bk_paths\.append blob exceeds cap/.test(iy0), 'append: 1MiB cap');
ok(/crc32\.update\(bArrA, 0, iB\)/.test(iy0), 'append: CRC32 over blob');
ok(/new FileOutputStream\(fileD, true\)/.test(iy0) && /new FileOutputStream\(fileA, true\)/.test(iy0), 'append: idx then dat FileOutputStream');
ok(/this\.o = false;[\s\S]{0,60}this\.d\.e\(new tz9\(cxcVar\)\)/.test(iy0), 'append: IOException -> invalidate + tz9');

// iy0.d read path
ok(/bk_paths\.ensureMmapCovers dat too large to mmap/.test(iy0), 'd: oversize guard log');
ok(/FileChannel\.MapMode\.READ_ONLY/.test(iy0), 'd: mmap READ_ONLY');
ok(/%04x-%08x-%08x/.test(iy0), 'page.id hex format = site-ts-idx');
ok(/xn7Var\.put\("note\.id"/.test(iy0) && /xn7Var\.put\("page\.id"/.test(iy0), 'd: note.id+page.id log fields');

// gy0 = per-page mmap state
ok(/public long b = 0;[\s\S]{0,60}public ByteBuffer c;/.test(gy0), 'gy0 = {b=size, c=mmap}');
ok(/qf3\.a\(byteBuffer\)/.test(gy0), 'gy0.a: unmap old via qf3');

console.log(`\nbk-paths-format replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
