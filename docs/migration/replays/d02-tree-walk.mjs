// Phase 1132 — njj.t DFS tree-walk + n4c.a codepoint→index
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const njj = R('njj'), n4c = R('n4c');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('njj.t(jxc,exc,rwc,ix4)', njj.includes('void t(jxc jxcVar, exc excVar, rwc rwcVar, ix4 ix4Var)'));
t('njj.t: null-exc→s() all-walk', njj.includes('s(jxcVar, rwcVar, ix4Var)'));
t('njj.t: Q root via ixc.a', njj.includes('Q(jxcVar, ixc.a)'));
t('njj.t: Q target via exc', njj.includes('Q(jxcVar, excVar)'));
t('njj.t: m() parent→child map', njj.includes('linkedHashMapM = m(qwcVarQ2)'));
t('njj.t: firstChildId lookup', njj.includes('firstChildId'));
t('njj.t: p() child list + u() index', njj.includes('p(jxcVar, hr5Var)') && njj.includes('u(hr5Var, listP, excVar2)'));
t('njj.t: vz3{i,list} DFS stack', njj.includes('new vz3(iU, listP)') && njj.includes('vz3Var.b'));
t('n4c.a codepoint→index', n4c.includes('int a(CharSequence charSequence, int i)'));
t('n4c.a: lz0→i / offsetByCodePoints', n4c.includes('charSequence instanceof lz0') && n4c.includes('Character.offsetByCodePoints'));
console.log('tree-walk replay: ' + n + '/10 checks green');
