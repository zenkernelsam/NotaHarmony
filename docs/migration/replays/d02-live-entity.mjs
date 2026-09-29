// Phase 1068 — qy0 live block + spec→live symmetry
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const qy0 = R('qy0'), ry0 = R('ry0'), m5d = R('m5d'), n5d = R('n5d');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('qy0: implements fi0', qy0.includes('implements fi0'));
t('qy0: wraps ry0 spec (field b)', qy0.includes('public final ry0 b'));
t('qy0: 12 fqb registers', (qy0.match(/public final fqb [a-z];/g) || []).length >= 12);
t('qy0: v09 o = kind + int p version', qy0.includes('v09 o') && qy0.includes('int p'));
t('qy0 fl6[] = {rotation,scale,zIndex}', (qy0.match(/new w1b\(qy0\.class/g) || []).length === 3 && qy0.includes('"rotation"') && qy0.includes('"scale"') && qy0.includes('"zIndex"'));
t('qy0 ctor: do6.g per spec snap', qy0.includes('qy0(ry0 ry0Var)') && qy0.includes('do6.g(yc6Var, yc6Var)'));
t('symmetry: m5d(n5d) live-shape', m5d.includes('m5d(n5d n5dVar)') && m5d.includes('this.b = n5dVar'));
t('shape spec n5d: ao2 payload', n5d.includes('ao2 ao2Var'));
t('block spec ry0: rl2 payload', ry0.includes('rl2 rl2Var'));
t('qy0: 3-prop vs m5d full transform', qy0.includes('getZIndex-tJoBMIg'));
console.log('live-entity replay: ' + n + '/10 checks green');
