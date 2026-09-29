// Phase 1022 — sxa Context holder + hl3 read-side
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const sxa = readFileSync(D + 'sxa.java', 'utf8');
const hl3 = readFileSync(D + 'hl3.java', 'utf8');
const cx6 = readFileSync(D + 'cx6.java', 'utf8');
const nr1 = readFileSync(D + 'nr1.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('sxa: Context-only (no methods)', !sxa.includes('public final Object') && /public final Context a;/.test(sxa));
t('sxa: single ctor', sxa.trim().includes('public sxa(Context context)'));
t('hl3: DELETE...IN', hl3.includes('DELETE FROM DraftNote WHERE noteId IN ('));
t('hl3: no INSERT (write elsewhere)', !hl3.includes('INSERT INTO `DraftNote`'));
t('hl3: batched Collection param', hl3.includes('a(Collection collection, ff2 ff2Var)'));
t('hl3: Room binder wp1(3)', hl3.includes('new wp1(this, 3)'));
t('cx6: check+getValue iface', cx6.includes('boolean a(') && cx6.includes('getValue('));
t('nr1: sxa dep', /public final sxa f;/.test(nr1));
t('nr1: jl3 dep (DraftNote repo)', /public final jl3 e;/.test(nr1));
t('q75: dt4 dep', readFileSync(D + 'q75.java', 'utf8').includes('public final dt4 b;'));
console.log('sxa-context replay: ' + n + '/10 checks green');
