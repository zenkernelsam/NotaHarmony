// Phase 981 — z7c binder + zp1 ClientOp + gk4.v + Room schema
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const z7c = readFileSync(`${ROOT}/z7c.java`, 'utf8');
const wp1 = readFileSync(`${ROOT}/wp1.java`, 'utf8');
const iq1 = readFileSync(`${ROOT}/iq1.java`, 'utf8');
const gk4 = readFileSync(`${ROOT}/gk4.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// z7c = statement binder interface
ok(/void h0\(int i, String str\)/.test(z7c), 'z7c.h0 = bindString');
ok(/void l\(int i, long j\)/.test(z7c), 'z7c.l = bindLong');
ok(/void o\(byte\[\] bArr, int i\)/.test(z7c), 'z7c.o = bindBlob');
ok(/void r\(int i\)/.test(z7c), 'z7c.r = bindNull');

// op bytes bound verbatim via ree.b
ok(/z7cVar\.o\(ree\.b\(uq9Var\), 2\)/.test(wp1), 'wp1: ree.b(uq9) -> col2 op blob');
ok(/z7cVar\.o\(ree\.b\(uq9Var\), 2\)/.test(iq1), 'iq1: ree.b(uq9) -> col2 op blob');
ok(/z7cVar\.o\(ttfVar2?\.a\(\), 1\)/.test(wp1), 'wp1: ttf.a() -> col1 noteId uuid bytes');
ok(/z7cVar\.l\(6, gk4\.v\(/.test(wp1) || /z7cVar\.l\(6, gk4\.v\(/.test(iq1), 'binder: gk4.v(opId) -> col6');

// gk4.v = qo5->long pack
ok(/static long v\(qo5 qo5Var\)/.test(gk4), 'gk4.v = qo5 packer');
ok(/\(\(\(long\) qo5Var\.d\(\)\) & 4294967295L\) << 32\) \| \(\(\(long\) qo5Var\.c\(\)\) & 65535\)/.test(gk4), 'gk4.v: (ts<<32)|(site&0xFFFF)');

// Room schema table names + key columns
for (const t of ['ClientNoteUpdate','ClientOp','NoteAsset','PermanentlyDeletedNote','SyncedFolderMetadata','SyncedNoteMetadata','SyncedOpMetadata']) {
  ok(wp1.includes('`' + t + '`'), `wp1: INSERT INTO ${t}`);
}
ok(/ClientOp` \(`noteId`,`op`,`uploadImmediately`,`hasTitle`,`title`,`opId`,`clientTime`\)/.test(wp1), 'ClientOp 7-col schema');
ok(/opsChecksum`,`offsetsChecksum`\)/.test(wp1), 'SyncedOpMetadata: checksum columns');
ok(/idempotencyKey/.test(wp1), 'ClientNoteUpdate: idempotencyKey');
ok(/linkAccessLevel`,`linkPermissionScope`,`userAccessLevel/.test(wp1), 'SyncedNoteMetadata: link-sharing cols');

console.log(`\nsqlite-persistence replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
