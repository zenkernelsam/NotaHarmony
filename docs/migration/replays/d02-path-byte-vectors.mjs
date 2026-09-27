// Phase 927 — ei7/nl8 路径字节向量层回归
// 证据：docs/migration/evidence/phase-927-path-byte-vectors.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const ei7 = rd('ei7.java');
const nl8 = rd('nl8.java');
const dm2 = rd('dm2.java');

ok(ei7.includes('implements hmf'), 'ei7 = byte iterator');
ok(ei7.includes('dm2Var.g(22)'), 'ei7 reads dm2.g(22) raw ByteBuffer slice');
ok(ei7.includes('this.I.get(this.J + i)'), 'ei7 zero-copy byte read');
ok(ei7.includes('ByteBuffer I'), 'ei7 wraps ByteBuffer');

ok(nl8.includes('implements jmf'), 'nl8 = mutable byte list');
ok(nl8.includes('new byte[i]'), 'nl8 byte[] backed');
ok(nl8.includes('(bArr.length * 3) / 2'), 'nl8 1.5x growth');
ok(nl8.includes('void b(byte b)'), 'nl8 append');
ok(nl8.includes('out of bounds for size'), 'nl8 bounds check');

// path fields are byte vectors (raw ByteBuffer via g), not struct vectors
ok(dm2.match(/Integer l\(\)[\s\S]{0,120}c\(24\)/), 'dm2 customPath len c(24)');
ok(!dm2.includes('xwd') || dm2.match(/v\(\)[\s\S]{0,40}qed/),
  'scale remains qed struct (paths are bytes)');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
