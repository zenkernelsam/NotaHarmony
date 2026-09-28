// Phase 970 — com.google.flatbuffers.a 写侧原语层
import { readFileSync } from 'node:fs';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/google/flatbuffers';
const a = readFileSync(`${SRC}/a.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// fields
ok(/public boolean l;/.test(a) && /public final ldj m;/.test(a), 'fields: l=forceDefaults, m=ldj allocator');
ok(/ByteOrder\.LITTLE_ENDIAN/.test(a), 'buffer is LITTLE_ENDIAN');

// startTable: nested guard + vtable scratch init
ok(/void C\(int i\)[\s\S]{0,120}object serialization must not be nested/.test(a), 'C: nested-object guard');
ok(/Arrays\.fill\(this\.d, 0, i, 0\)/.test(a) && /this\.f = true;\s*this\.h = r\(\)/.test(a), 'C: vtable clear + nested flag + objStart');

// startVector
ok(/void D\(int i, int i2, int i3\)[\s\S]{0,150}this\.k = i2/.test(a), 'D: stores vector count k');

// default-skip writes with forceDefaults bypass
ok(/void a\(int i, boolean z, boolean z2\)[\s\S]{0,60}this\.l \|\| z != z2/.test(a), 'a: bool default-skip || l');
ok(/void e\(int i, int i2, int i3\)[\s\S]{0,60}this\.l \|\| i2 != i3/.test(a), 'e: int default-skip || l');
ok(/void f\(int i, long j\)[\s\S]{0,60}this\.l \|\| j != 0/.test(a), 'f: long default-skip || l');
ok(/void i\(int i, short s\)[\s\S]{0,60}this\.l \|\| s != 0/.test(a), 'i: short default-skip || l');

// offset/struct field
ok(/void g\(int i\)[\s\S]{0,60}w\(\(r\(\) - i\) \+ 4\)/.test(a), 'g: rel uoffset = (r()-i)+4');
ok(/void j\(int i, int i2\)[\s\S]{0,150}struct must be serialized inline/.test(a), 'j: struct must be inline');

// slot + endVector
ok(/void B\(int i\)[\s\S]{0,40}this\.d\[i\] = r\(\)/.test(a), 'B: slot records r()');
ok(/int o\(\)[\s\S]{0,300}w\(this\.k\)/.test(a), 'o: endVector writes count');

// endTable: trailing-zero trim + vtable dedup
ok(/while \(i2 >= 0 && this\.d\[i2\] == 0\)/.test(a), 'n: trailing-zero vtable trim');
ok(/y\(\(short\) \(\(i2 \+ 3\) \* 2\)\)/.test(a), 'n: vtable size = (slots+3)*2');

// required check
ok(/void z\(int i, int i2\)[\s\S]{0,200}getShort[\s\S]{0,200}must be set/.test(a), 'z: required vtable-slot check throws');

// finish + sizedByteArray guard
ok(/void p\(int i\)[\s\S]{0,150}this\.g = true/.test(a), 'p: finish sets g');
ok(/void q\(\)[\s\S]{0,100}only access the serialized buffer after/.test(a), 'q: not-finished guard');
ok(/byte\[\] A\(\)/.test(a), 'A: sizedByteArray');

// pooled ctor path via c8d
ok(/public a\(c8d c8dVar, ByteBuffer byteBuffer\)/.test(a), 'ctor: a(c8d,bb) pooled');
ok(/bk4\.R/.test(a), 'ctor: default allocator bk4.R');

console.log(`\nbuilder-primitives replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
