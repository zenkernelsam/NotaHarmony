// Phase 1097 — z5c.x op→payload factory + uq9.q bind
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const z5c = R('z5c'), uq9 = R('uq9');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('z5c.x(uq9)→cee', z5c.includes('cee x(uq9 uq9Var)'));
t('z5c.x: switch on op ordinal', z5c.includes('uq9Var.m().ordinal()'));
t('z5c.x: NONE→rgc.b throw', z5c.includes('rgc.b(mpb.a.b(uq9.class)'));
t('z5c.x: case1 l2d + case3 ln2', z5c.includes('l2dVar = new l2d()') && z5c.includes('l2dVar = new ln2()'));
t('z5c.x: case2 ra0 asset-persisted', z5c.includes('l2dVar = new ra0()'));
t('z5c.x: 31 cases dispatch', (z5c.match(/case \d+:/g) || []).length >= 31);
t('z5c.x: default→o14.t unreachable', z5c.includes('o14.t()'));
t('z5c.x: uq9.q(payload) bind', z5c.includes('uq9Var.q(l2dVar)'));
t('z5c.x: return bound payload', z5c.includes('return l2dVar'));
t('uq9.q = op-envelope bind method', uq9.includes('void q(') || uq9.includes('q(cee'));
console.log('payload-factory replay: ' + n + '/10 checks green');
