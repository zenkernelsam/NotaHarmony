// Phase 1236 — ww0 haptic-strength animator
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ww0 = R('ww0.java');
t('ww0 rj5 down add', ww0.includes('t76Var instanceof rj5') && ww0.includes('arrayList.add'));
t('ww0 sj5 removes rj5.a', ww0.includes('t76Var instanceof sj5') && ww0.includes('((sj5) t76Var).a'));
t('ww0 zo4/ap4 pair', ww0.includes('t76Var instanceof zo4') && ww0.includes('((ap4) t76Var).a'));
t('ww0 mn3/nn3 pair', ww0.includes('t76Var instanceof mn3') && ww0.includes('((nn3) t76Var).a'));
t('ww0 ln3 end', ww0.includes('t76Var instanceof ln3'));
t('ww0 au1.o1 top', ww0.includes('au1.o1(arrayList)'));
t('ww0 ba6.o dedup', ww0.includes('ba6.o'));
t('ww0 weight 0.08', ww0.includes('f = 0.08f'));
t('ww0 weights 0.1+0.16', ww0.includes('0.1f') && ww0.includes('0.16f'));
t('ww0 vhf 45ms tween', ww0.includes('new vhf(45, ds3.c, 2)'));
console.log('ww0-haptic replay: ' + n + '/10 checks green');
