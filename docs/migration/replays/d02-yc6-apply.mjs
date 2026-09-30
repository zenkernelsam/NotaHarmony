// Phase 1139 — yc6.z spatial apply + yc6.G commit
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const yc6 = R('yc6');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('yc6.z(e0a,bool,al2,list)', yc6.includes('void z(e0a e0aVar, boolean z, al2 al2Var, List list)'));
t('yc6.G(list,al2,list,ff2) commit', yc6.includes('Object G(List list, al2 al2Var, List list2, ff2 ff2Var)'));
t('z: wia store = this.L', yc6.includes('(wia) this.L'));
t('z: k11 scratch bounds', yc6.includes('k11 k11Var = new k11()'));
t('z: packed key site16|time32<<32', yc6.includes('65535') && yc6.includes('4294967295'));
t('z: igf.n spatial lookup', yc6.includes('wiaVar.c.n(jC, 0, wiaVar)'));
t('z: wia.d cache invalidate', yc6.includes('wiaVar.d = null'));
t('z: vnd node → v.a(bounds)', yc6.includes('vndVar.a(k11Var)'));
t('z: ba6.P bounds entity iter', yc6.includes('ba6.P(k11Var, list)'));
t('z: e0a.b plan ops loop', yc6.includes('e0aVar.b'));
console.log('yc6-apply replay: ' + n + '/10 checks green');
