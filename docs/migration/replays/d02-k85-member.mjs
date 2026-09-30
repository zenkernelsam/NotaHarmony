// Phase 1145 — k85/l85 member-collection spec↔live
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const k85 = R('k85'), l85 = R('l85');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('k85 implements h85,xy3', k85.includes('implements h85, xy3'));
t('k85 "members" w1b descriptor', k85.includes('"members"') && k85.includes('getMembers()Ljava/util/List;'));
t('k85 fqb c register', k85.includes('fqb c'));
t('k85 M() = c.b reg value', k85.includes('(List) this.c.b'));
t('k85(l85) spec→live ctor', k85.includes('k85(l85 l85Var)'));
t('k85 build()→yy3', k85.includes('yy3 build()'));
t('l85 implements yy3,h85', l85.includes('implements yy3, h85'));
t('l85 "members" descriptor', l85.includes('"members"'));
t('l85(uq9,cm2,yc6) CREATE-ctor', l85.includes('l85(uq9 uq9Var, cm2 cm2Var, yc6 yc6Var)'));
t('l85 M() = xj2.v delegated', l85.includes('xj2.v(this.d, h[0])'));
console.log('k85-member replay: ' + n + '/10 checks green');
