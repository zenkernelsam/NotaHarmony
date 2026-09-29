// Phase 1029 — manifest.json fields + w59 continuation correction
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const yk9 = readFileSync(D + 'yk9.java', 'utf8');
const w59 = readFileSync(D + 'w59.java', 'utf8');
const y59 = readFileSync(D + 'y59.java', 'utf8');
const zk9 = readFileSync(D + 'zk9.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('yk9: version key', yk9.includes('"version"'));
t('yk9: noteBundle key', yk9.includes('"noteBundle"'));
t('yk9: assets dir', yk9.includes('"assets/"'));
t('w59 extends ff2 (continuation)', /class w59 extends ff2/.test(w59));
t('w59: ttf+String+lq4+Closeable', /public ttf I;/.test(w59) && /public String J;/.test(w59) && /public lq4 K;/.test(w59) && /public Closeable L;/.test(w59));
t('w59: bool+int+Object+y59', /public boolean M;/.test(w59) && /public int N;/.test(w59) && w59.includes('Object O;') && /y59 P;/.test(w59));
t('zk9.a param w59 = continuation', zk9.includes('w59 w59Var'));
t('y59: outer coroutine', /class y59|interface y59/.test(y59));
const pa0 = readFileSync(D + 'pa0.java', 'utf8');
t('pa0 produces wa0 (996)', /class pa0|interface pa0/.test(pa0));
t('yk9: wx4 coroutine carrier', yk9.includes('extends n8e') || yk9.includes('wx4'));
console.log('manifest-fields replay: ' + n + '/10 checks green');
