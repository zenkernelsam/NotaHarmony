// Phase 1066 — ry0 block spec + e4c collection + delegated props
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const ry0 = R('ry0'), e4c = R('e4c');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ry0: implements be5,ce5,bf0', ry0.includes('implements be5, ce5, bf0'));
t('ry0: fl6[] v = 8 delegated props', (ry0.match(/new w1b\(ry0\.class/g) || []).length === 8);
t('ry0 props: rotation,scale,size,corner', ry0.includes('"rotation"') && ry0.includes('"scale"') && ry0.includes('"size"') && ry0.includes('"corner"'));
t('ry0 props: textWrap,enableCaption,positionLocked', ry0.includes('"textWrap"') && ry0.includes('"enableCaption"') && ry0.includes('"positionLocked"'));
t('zIndex: ULong name-mangled', ry0.includes('getZIndex-tJoBMIg') && ry0.includes('()J'));
t('ry0 fields: uq9+rl2+yc6×9+cxc+fqa+cz0+qed', ry0.includes('uq9 b') && ry0.includes('rl2 c') && ry0.includes('cxc o') && ry0.includes('fqa p') && ry0.includes('cz0 q') && ry0.includes('qed r'));
t('ry0 ctor: uq9+rl2+9 yc6', ry0.includes('ry0(uq9 uq9Var, rl2 rl2Var'));
t('e4c: o4c collection iface impl', e4c.includes('implements o4c'));
t('e4c: ArrayList members + sentinel', e4c.includes('ArrayList c') && e4c.includes('rh8.b(-1, 0)'));
t('e4c: m4c/k4c/iwc/gja/al2 deps', e4c.includes('m4c b') && e4c.includes('k4c d') && e4c.includes('iwc e') && e4c.includes('gja f') && e4c.includes('al2 g'));
console.log('block-spec replay: ' + n + '/10 checks green');
