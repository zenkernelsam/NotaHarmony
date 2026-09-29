// Phase 984 — nce.A verified mmap + u63 ref + x63 format enum + fsi.r CRC32
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const nce = readFileSync(`${ROOT}/nce.java`, 'utf8');
const u63 = readFileSync(`${ROOT}/u63.java`, 'utf8');
const jwh = readFileSync(`${ROOT}/jwh.java`, 'utf8');
const fsi = readFileSync(`${ROOT}/fsi.java`, 'utf8');
const x63 = readFileSync(`${ROOT}/x63.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// u63 = deferred-ops file ref {rowId,noteId,short,format,size,crc32}
ok(/public u63\(long j, ttf ttfVar, short s, x63 x63Var, long j2, int i\)/.test(u63), 'u63 ctor signature');
ok(/return this\.f;\s*}/.test(u63), 'u63.a() = crc32 field');
ok(/return this\.e;[\s\S]{0,80}return this\.a;[\s\S]{0,80}return this\.b;/.test(u63), 'u63 b/c/d = size/rowId/noteId');

// nce.A = verified mmap read
ok(/FileChannel\.open\(this\.a\.a\(u63Var\.d\(\), u63Var\.c\(\)\)\.toPath\(\), StandardOpenOption\.READ\)/.test(nce), 'nce.A: path=fn(noteId,rowId) READ');
ok(/if \(size == 0\)[\s\S]{0,120}Deferred ops file is empty for row/.test(nce), 'nce.A: empty -> IOException');
ok(/if \(size != u63Var\.b\(\)\)[\s\S]{0,200}Deferred ops file size mismatch/.test(nce), 'nce.A: size mismatch -> IOException');
ok(/fileChannelOpen\.map\(FileChannel\.MapMode\.READ_ONLY, 0L, size\)/.test(nce), 'nce.A: READ_ONLY mmap');
ok(/int iR = fsi\.r\(map, bArr\);\s*if \(iR == u63Var\.a\(\)\)/.test(nce), 'nce.A: crc32 check vs u63.f');
ok(/Deferred ops file checksum mismatch for row/.test(nce), 'nce.A: checksum mismatch -> log+null');
ok(/NoSuchFileException[\s\S]{0,200}Deferred ops file missing for row/.test(nce), 'nce.A: missing -> IOException');

// jwh.a = polymorphic root read by x63 ordinal
ok(/iOrdinal == 0[\s\S]{0,200}new r29\(\)[\s\S]{0,300}new uae\(r29Var\)/.test(jwh), 'jwh.a: ordinal 0 -> r29/uae');
ok(/iOrdinal == 1[\s\S]{0,200}new vt9\(\)[\s\S]{0,300}new yae\(vt9Var\)/.test(jwh), 'jwh.a: ordinal 1 -> vt9/yae');
ok(/iOrdinal != 2[\s\S]{0,120}o14\.t\(\)[\s\S]{0,200}new zgb\(\)[\s\S]{0,300}new uae\(zgbVar\)/.test(jwh), 'jwh.a: ordinal 2 -> zgb/uae');
ok(/mappedByteBuffer\.position\(\) \+ mappedByteBuffer\.getInt\(mappedByteBuffer\.position\(\)\)/.test(jwh), 'jwh.a: uoffset root read');

// x63 = 3-value enum
const x63Count = (x63.match(/new x63\(/g) || []).length;
ok(x63Count === 3, `x63: exactly 3 enum values (got ${x63Count})`);

// fsi.r = CRC32 over buffer via scratch
ok(/import java\.util\.zip\.CRC32/.test(fsi), 'fsi: CRC32 import');
ok(/public static final int r\(ByteBuffer byteBuffer, byte\[\] bArr\)[\s\S]{0,200}new CRC32\(\)/.test(fsi), 'fsi.r: CRC32');
ok(/byteBuffer\.duplicate\(\)[\s\S]{0,60}position\(0\)/.test(fsi), 'fsi.r: duplicate + rewind');
ok(/Math\.min\(byteBufferDuplicate\.remaining\(\), bArr\.length\)/.test(fsi), 'fsi.r: scratch-chunked update');
ok(/\(int\) crc32\.getValue\(\)/.test(fsi), 'fsi.r: (int)getValue');

console.log(`\ndeferred-ops-file replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
