// Phase 1052 — lv2 vector-accessor pattern + persistent collections
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const lv2 = R('lv2'), th7 = R('th7'), hw3 = R('hw3'), m18 = R('m18');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('lv2: canonical vector read (c→i→loop→E)', lv2.includes('m18.S()') && lv2.includes('m18.E(th7VarS)') && lv2.includes('hw3.I'));
t('lv2: M(wd8) inks→qo5', lv2.includes('List M(wd8 ') && lv2.includes('wd8Var.B(qo5Var'));
t('lv2: N(qub)/O(f2c) cxc vectors', lv2.includes('List N(qub ') && lv2.includes('List O(f2c ') && lv2.includes('qubVar.l(i2, cxcVar)'));
t('lv2: I/J/W/X delete lists→th7', lv2.includes('th7 I(s83 ') && lv2.includes('th7 J(s83 ') && lv2.includes('th7 W(s83 ') && lv2.includes('th7 X(s83 '));
t('lv2: T(r29)/U(vt9) op materializers', lv2.includes('List T(r29 ') && lv2.includes('List U(vt9 '));
t('lv2: encoded-path accessors w/x', lv2.includes('lv2') === false || (lv2.includes('ei7 A(dm2 ') && lv2.includes('nl8 B(dm2 ')));
t('lv2: ±INFINITY bounds consts', lv2.includes('Float.POSITIVE_INFINITY') && lv2.includes('Float.NEGATIVE_INFINITY') && lv2.includes('new rz('));
t('th7: persistent builder {I array,J size,K frozen}', th7.includes('public Object[] I') && th7.includes('public int J') && th7.includes('public boolean K'));
t('th7: frozen EMPTY L', th7.includes('K = true') && th7.includes('L = th7Var'));
t('th7 extends u4', th7.includes('extends u4'));
t('hw3: empty-list singleton I', hw3.includes('public static final hw3 I = new hw3()') && hw3.includes('implements List'));
t('m18: S() builder + E(List) freeze', m18.includes('th7 S()') && m18.includes('th7 E(List'));
console.log('vector-accessors replay: ' + n + '/12 checks green');
