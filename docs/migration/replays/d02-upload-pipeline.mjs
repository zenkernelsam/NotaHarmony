// Phase 997 — 上传管线（oq1/wqf/aa6.r0/d8d/ys2.k/q89）
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const oq1 = readFileSync(D + 'oq1.java', 'utf8');
const wqf = readFileSync(D + 'wqf.java', 'utf8');
const aa6 = readFileSync(D + 'aa6.java', 'utf8');
const d8d = readFileSync(D + 'd8d.java', 'utf8');
const nwb = readFileSync(D + 'nwb.java', 'utf8');
const ys2 = readFileSync(D + 'ys2.java', 'utf8');
const q89 = readFileSync(D + 'q89.java', 'utf8');
const lv2 = readFileSync(D + 'lv2.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// oq1 upload client
t('oq1: uploadAppendedOps lock', oq1.includes('pv2.a("uploadAppendedOps"'));
t('oq1: createNote first-op CreatePage check', oq1.includes('CreatePage op with positive pageCount not found'));
t('oq1: appendOps unwrap via ys2.k', /ys2\.k\(\(vyb\) obj,\s*"appendOps"\)/.test(oq1));
t('oq1: last-op clientTime for createdAt', oq1.includes('((uq9) au1.c1(list)).k()'));
t('oq1: ops->d8d stream via aa6.r0', oq1.includes('aa6.r0(list)'));
// wqf retrofit
t('wqf: POST append endpoint', wqf.includes('"collab-api/note/{id}/append"'));
t('wqf: siteId query param', /@b7b\("siteId"\) short/.test(wqf));
t('wqf: POST create endpoint', wqf.includes('"collab-api/note/create"'));
t('wqf: createdAt long param', /@b7b\("createdAt"\) long/.test(wqf));
// d8d RequestBody
t('d8d extends nwb(RequestBody) + AutoCloseable', /class d8d extends nwb implements AutoCloseable/.test(d8d));
t('d8d: octet-stream content type', d8d.includes('"application/octet-stream"'));
t('d8d.m: position+write zero-copy', /byteBuffer\.position\(i\);\s*o51Var\.write\(byteBuffer\)/.test(d8d));
t('d8d.close: shm release', /public final void close\(\)\s*\{\s*this\.J\.close\(\)/.test(d8d));
t('nwb = RequestBody (a/b/m abstract)', nwb.includes('abstract long a()') && nwb.includes('abstract h58 b()') && nwb.includes('abstract void m(o51'));
// aa6.r0 ops->bundle
const r0 = aa6.slice(aa6.indexOf('d8d r0(List'));
t('aa6.r0: shm 16KB builder', r0.includes('l2(16384)') && r0.includes('new a(c8dVar'));
t('aa6.r0: per-op ree.a + D(4) vector', r0.includes('ree.a((cee)') && r0.includes('aVar.D(4, size, 4)'));
// ys2.k + q89
const k = ys2.slice(ys2.indexOf('Object k(vyb'));
t('ys2.k: LE root to q89', /order\(ByteOrder\.LITTLE_ENDIAN\);\s*q89Var\.d\(/.test(k));
t('ys2.k: Malformed NoteMutationResponse log', k.includes('Malformed NoteMutationResponse') && k.includes('SERVER_PERSISTENCE'));
t('q89: noteId utf required @f4', /int iC = c\(4\);[\s\S]{0,200}required\) field noteId/.test(q89));
t('q89: toString names fields', q89.includes('NoteMutationResponse(noteId='));
t('lv2.t: acks->vq9 materialize', /List t\(q89[\s\S]{0,400}new vq9\(\)[\s\S]{0,200}j\(vq9Var, i2\)/.test(lv2));
console.log('upload-pipeline replay: ' + n + '/21 checks green');
