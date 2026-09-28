// Phase 955 — dk4 池化 builder + c8d SharedMemory 分配器
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const dk4 = readFileSync(`${ROOT}/dk4.java`, 'utf8');
const c8d = readFileSync(`${ROOT}/c8d.java`, 'utf8');
const k1a = readFileSync(`${ROOT}/k1a.java`, 'utf8');
const ck4 = readFileSync(`${ROOT}/ck4.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// dk4 = pooled builder factory
ok(/"FB_BYTE_BUFFER_HOLDER", "getFB_BYTE_BUFFER_HOLDER\(\)Ljava\/nio\/ByteBuffer;"/.test(dk4), 'dk4: FB_BYTE_BUFFER_HOLDER pool prop');
ok(/new cz8\(new ra\(28\), ck4\.P\)/.test(dk4), 'dk4: cz8 pool(factory ra(28), reset ck4.P)');
ok(/x82\.x\(b, a\[0\]\)/.test(dk4) && /new a\(c8dVar, \(ByteBuffer\) objX\)/.test(dk4), 'dk4.a = acquire BB + new a(c8d,bb)');

// ck4.P = ByteBuffer::clear reset lambda
ok(/"clear", "clear\(\)Ljava\/nio\/Buffer;"/.test(ck4) && /byteBuffer\.clear\(\)/.test(ck4), 'ck4.P = ByteBuffer::clear reset');

// c8d = SharedMemory-backed allocator
ok(/class c8d extends ldj implements AutoCloseable/.test(c8d), 'c8d extends ldj AutoCloseable');
ok(/ArrayList R = new ArrayList\(2\)/.test(c8d), 'c8d.R = k1a tracking list');
ok(/SharedMemory\.create\("fbb-shm", i\)/.test(c8d), 'l2: SharedMemory.create("fbb-shm")');
ok(/mapReadWrite\(\)\.order\(ByteOrder\.LITTLE_ENDIAN\)/.test(c8d), 'l2: mapReadWrite + LITTLE_ENDIAN');
ok(/SharedMemory\.mapReadWrite failed for capacity=/.test(c8d), 'l2: map fail IOException');
ok(/SharedMemory\.create failed for capacity=/.test(c8d), 'l2: create fail IOException');
ok(/SharedMemory\.unmap/.test(c8d) && /sharedMemory\.close\(\)/.test(c8d), 'v2/close: unmap + shm.close');

// k1a = (ByteBuffer, SharedMemory) pair
ok(/public final Object I;[\s\S]{0,80}public final Object J;/.test(k1a), 'k1a = generic {I=bb, J=shm} pair');

console.log(`\ndk4-c8d-allocator replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
