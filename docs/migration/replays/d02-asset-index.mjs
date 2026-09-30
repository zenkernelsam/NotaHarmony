// Phase 1143 — v69.a asset-index write + za0/ua0/qa0
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const v69 = R('v69'), za0 = R('za0'), pa0 = R('pa0'), ua0 = R('ua0');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('v69.a(pa0,List)', v69.includes('void a(pa0 pa0Var, List list)'));
t('a: pa0 null-guard', v69.includes('if (pa0Var == null)'));
t('a: pa0.a().j()→ua0 key', v69.includes('ua0 ua0VarJ = pa0Var.a().j()'));
t('a: h() gja annotation map', v69.includes('(za0) h().get(ua0VarJ)') && v69.includes('h().put(ua0VarJ'));
t('a: za0.a copy-with merge', v69.includes('za0.a(za0Var, ys2.J(za0Var.b, list), 1)'));
t('a: new za0(qa0.I, X1 set)', v69.includes('new za0(qa0.I, au1.X1(list))'));
t('za0{qa0,Set} + copy-with', za0.includes('za0(qa0 qa0Var, Set set)') && za0.includes('za0 a(za0 za0Var'));
t('pa0 interface', pa0.includes('interface pa0'));
t('ua0 FlatBuffers table (xwd,ka4)', ua0.includes('extends xwd implements ka4'));
t('v69.w→x suspend delegate', v69.includes('objX = x(collection, t69Var)'));
console.log('asset-index replay: ' + n + '/10 checks green');
