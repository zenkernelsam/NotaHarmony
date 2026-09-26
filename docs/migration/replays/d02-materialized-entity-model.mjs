// Phase 864 — 物化实体模型（ly3/qg2/yy3/mz9 + 7 Impl + yc6）登记回归
// 证据：docs/migration/evidence/phase-864-materialized-entity-model.md
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const HARM = 'note/src/main/ets';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- 接口栈 ----
const ly3 = readFileSync(join(SRC, 'ly3.java'), 'utf8');
ok(ly3.includes('extends qg2'), 'ly3 extends qg2');
ok(ly3.includes('uq9 O()'), 'ly3.O() returns owning uq9 Op');
ok(ly3.includes('qo5 getId()'), 'ly3.getId() = op qo5');
ok(ly3.includes('O().o() != null'), 'ly3.I() synced check via op field');

const qg2 = readFileSync(join(SRC, 'qg2.java'), 'utf8');
ok(qg2.includes('interface qg2'), 'qg2 interface exists');
ok(qg2.includes('u(a aVar)'), 'qg2.u() reserialize-as-op contract');

const yy3 = readFileSync(join(SRC, 'yy3.java'), 'utf8');
ok(yy3.includes('extends ly3, qg2') && yy3.includes('xy3 builder()'),
  'yy3 = ly3+qg2 with builder()');
const mz9 = readFileSync(join(SRC, 'mz9.java'), 'utf8');
ok(mz9.includes('extends ly3'), 'mz9 extends ly3');
ok(mz9.includes('nz9 B()') && mz9.includes('ln2 z()'), 'mz9 page contract: background+payload');

// ---- 7 物化实现 ----
const impls = { wz9: 'PageImpl', s06: 'InkImpl', m4c: 'RichTextImpl',
                n5d: 'ShapeImpl', l85: 'GroupImpl', gkb: 'RecordingImpl' };
for (const [cls, name] of Object.entries(impls)) {
  ok(readFileSync(join(SRC, cls + '.java'), 'utf8').includes(name + '('),
    `${cls} = ${name}`);
}
ok(readFileSync(join(SRC, 'vz9.java'), 'utf8').includes('implements mz9, xy3'),
  'vz9 = page builder (mz9+xy3)');

// ---- wz9 寄存器物化 ----
const wz9 = readFileSync(join(SRC, 'wz9.java'), 'utf8');
ok(wz9.includes('backgroundRegister=') && wz9.includes('bookmarkedRegister=') &&
   wz9.includes('pageInAssetRegister='), 'wz9 carries three yc6 registers');
ok(wz9.includes('oz9.BOOKMARKED'), 'wz9 materializes bookmarked from register winner');
ok(wz9.includes('nti.g(uq9Var.l(), i)'), 'wz9 derives cxc from op-id+index');
ok(wz9.includes('haj.a(null, nz9VarB, 1, (oz9) this.f.K, 16)'),
  'wz9.u() re-serializes state as new CreatePage variant');

// ---- yc6 寄存器宿主 ----
ok(readFileSync(join(SRC, 'yc6.java'), 'utf8').includes('public Object K'),
  'yc6 .K winner slot');

// ---- Harmony 等价 ----
const oid = readFileSync(join(HARM, 'data/OperationIdentity.ets'), 'utf8');
ok(oid.includes('MAX_EDITOR_SITE_ID: number = 0xFFFF'), 'siteId u16 bound = qo5 site');
ok(oid.includes('MAX_OPERATION_TIMESTAMP: number = 0xFFFFFFFF'), 'timestamp u32 bound');
ok(oid.includes('op:${identity.timestamp.toString(16)}:${identity.siteId.toString(16)}'),
  'op:<ts>:<site> provenance encoding');
ok(oid.includes('decodeOperationId'), 'op-id decode exists');
const opStore = readFileSync(join(HARM, 'data/OpStoreImpl.ets'), 'utf8');
ok(opStore.includes('op_id') && opStore.includes('operation_index'),
  'op rows carry provenance (op_id + index)');
ok(opStore.includes('encodeOperationId(identity)'), 'op store encodes identity');
const nbpi = readFileSync(join(HARM, 'data/OriginalNoteBundlePageIdentity.ets'), 'utf8');
ok(nbpi.includes('bookmarkWinner') || nbpi.includes('Winner'), 'winner-row materialization');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
