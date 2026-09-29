// Phase 1028 — export bundle (zk9/yk9)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const zk9 = readFileSync(D + 'zk9.java', 'utf8');
const yk9 = readFileSync(D + 'yk9.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('zk9: Context+k79 lazy', zk9.includes('public final Context a;') && zk9.includes('z5c.b(new k79(13))'));
t('zk9.a: export entry sig', zk9.includes('public final Object a(x09 x09Var, utf utfVar, String str, String str2, boolean z, w59 w59Var)'));
t('zk9.a: yk9 coroutine', zk9.includes('new yk9(') && zk9.includes('xj2.T(t13.K'));
t('yk9: wx4 lambda', yk9.includes('implements wx4') || yk9.includes('extends n8e'));
t('yk9: manifest.json', yk9.includes('"manifest.json"'));
t('yk9: noteBundle', yk9.includes('"noteBundle"'));
t('yk9: assets dir', yk9.includes('"assets/"'));
// pa0 asset wrappers produce manifest metadata
const pa0 = readFileSync(D + 'pa0.java', 'utf8');
t('pa0: asset wrapper (from 996)', /class pa0|interface pa0/.test(pa0));
// w59 = progress sink
t('w59 sink param', zk9.includes('w59 w59Var'));
const w59 = readFileSync(D + 'w59.java', 'utf8');
t('w59: progress/result', /class w59|interface w59/.test(w59));
console.log('export-bundle replay: ' + n + '/10 checks green');
