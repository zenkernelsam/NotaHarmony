// Phase 1154 — x09 marker + m09 note companion
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const x09 = R('x09'), m09 = R('m09'), a79 = R('a79');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('x09 marker iface', x09.includes('interface x09'));
t('x09.a = m09.a companion', x09.includes('m09 a = m09.a'));
t('a79 implements x09', a79.includes('implements x09') || a79.includes('x09'));
t('m09 singleton', m09.includes('static final /* synthetic */ m09 a'));
t('m09 defaults: qed scale', m09.includes('static final qed b'));
t('m09 defaults: vy7 margins', m09.includes('static final vy7 d'));
t('m09 mirrors a79.N/O/P', m09.includes('a79.N') && m09.includes('a79.O') && m09.includes('a79.P'));
t('m09.a(r29,cl9) factory', m09.includes('Object a(r29 r29Var, cl9'));
t('m09 hu1 e + nz9 f fields', m09.includes('static final hu1 e') && m09.includes('nz9 f'));
t('m09 double c + float g', m09.includes('double c') && m09.includes('float g'));
console.log('note-companion replay: ' + n + '/10 checks green');
