// Phase 1064 — m5d CRDT entity (14 fqb regs) + n5d spec + do6.g init
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const m5d = R('m5d'), ei0 = R('ei0'), fi0 = R('fi0');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('m5d: implements be5+k5d+fi0', m5d.includes('implements be5, k5d, fi0'));
t('m5d: 14 fqb register fields', (m5d.match(/public final fqb [a-z];/g) || []).length >= 14);
t('m5d ctor: spec→do6.g(snap,snap) init', m5d.includes('m5d(n5d n5dVar)') && m5d.includes('do6.g(yc6Var, yc6Var)'));
t('fi0: o/n/w/J register accessors', fi0.includes('fqb J();') && fi0.includes('fqb n();') && fi0.includes('fqb o();') && fi0.includes('fqb w();'));
t('accessor map: o→c n→d w→e J→f', /o\(\) \{\s+return this\.c;/.test(m5d) && /n\(\) \{\s+return this\.d;/.test(m5d) && /w\(\) \{\s+return this\.e;/.test(m5d) && /J\(\) \{\s+return this\.f;/.test(m5d));
t('be5.G(): materialize reads reg.b', m5d.includes('(v4d) this.g.b') && m5d.includes('this.l.b').length === undefined || m5d.includes('this.l.b'));
t('ei0: bound property ref (v1b + get switch)', ei0.includes('extends v1b') && ei0.includes('public final Object get()'));
t('m5d.A(): version counter r++', m5d.includes('this.r++;'));
t('m5d: fl6[] KProperty delegate array', m5d.includes('fl6[] fl6VarArr = w'));
t('k5d iface exists', R('k5d').length > 0);
console.log('crdt-entity replay: ' + n + '/10 checks green');
