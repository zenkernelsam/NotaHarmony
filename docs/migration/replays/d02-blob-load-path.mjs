// Phase 979 — qud mmap 容器 + uae 版本闸 + lv2.T ops 物化
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const qud = readFileSync(`${ROOT}/qud.java`, 'utf8');
const zac = readFileSync(`${ROOT}/zac.java`, 'utf8');
const nce = readFileSync(`${ROOT}/nce.java`, 'utf8');
const ba6 = readFileSync(`${ROOT}/ba6.java`, 'utf8');
const lv2 = readFileSync(`${ROOT}/lv2.java`, 'utf8');
const uae = readFileSync(`${ROOT}/uae.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// qud = mmap blob container
ok(/class qud extends zac/.test(qud), 'qud extends zac(Closeable)');
ok(/public final MappedByteBuffer J;/.test(qud), 'qud.J = MappedByteBuffer payload');
ok(/this\.M\.delete\(\)/.test(qud), 'qud.a(): delete-on-close unless N');
ok(/AtomicBoolean I/.test(zac), 'zac: AtomicBoolean I');

// nce load path: uhj.n + version gate + lv2.T
ok(/r29 r29VarN = uhj\.n\(qudVar\.J\)/.test(nce), 'nce: uhj.n(qud.J) root read');
ok(/new uae\(r29VarN\)/.test(nce), 'nce: uae view over r29');
ok(/ba6\.w\(uaeVar2\.b\(\) & 65535, rgc\.a & 65535\) > 0/.test(nce), 'nce: u16 schemaVersion gate vs rgc.a');
ok(/lv2\.T\(r29Var2\)/.test(nce), 'nce: lv2.T ops materialization');
ok(/Skipping unreadable deferred ops file/.test(nce), 'nce: deferred-ops file path exists');
ok(/StaleSyncedNoteException|CorruptedSyncedOpException/.test(nce), 'nce: synced-op exceptions');

// uae.b = schemaVersion short
ok(/public final short b\(\)/.test(uae), 'uae.b() = schemaVersion view');

// ba6.w = Integer.compare
ok(/static int w\(int i, int i2\)[\s\S]{0,80}i < i2[\s\S]{0,60}return -1/.test(ba6), 'ba6.w = compare()');

// lv2.T/U materializers
ok(/static final List T\(r29 r29Var\)/.test(lv2), 'lv2.T = r29 ops materializer');
ok(/r29Var\.r\(uq9Var, i2\)/.test(lv2), 'lv2.T: per-index r29.r(uq9,i)');
ok(/static final List U\(vt9 vt9Var\)/.test(lv2) && /vt9Var\.l\(uq9Var, i2\)/.test(lv2), 'lv2.U = vt9 ops materializer');
ok(/m18\.S\(\)/.test(lv2) && /m18\.E\(th7VarS\)/.test(lv2) && /hw3\.I/.test(lv2), 'lv2: build+freeze+empty sentinel');

console.log(`\nblob-load-path replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
