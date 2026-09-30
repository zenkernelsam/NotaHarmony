// Phase 1209 — vle.G selection geometry (wh8 Layout / wpe / ip4)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const vle = R('vle.java');
t('vle.A delegates to u8e', vle.includes('this.j0.A(iqaVar, jqaVar, j)'));
t('vle.G(ip4) exists', vle.includes('void G(ip4'));
t('vle.G same-line cmb', vle.includes('new cmb(Math.min(fB, fB2)'));
t('vle.G multi-line wpe.j', vle.includes('wpeVarC.j(jqe.g(j), jqe.f(j))'));
t('vle.G clips mv6.J visible', vle.includes('mv6Var.J(mv6VarE, false)'));
t('vle.G empty t3i.O', vle.includes('t3i.O'));
const wh8 = R('wh8.java');
t('wh8 uses android.text.Layout', wh8.includes('android.text.Layout'));
t('ip4 f(cmb) iface', R('ip4.java').includes('f(cmb'));
const wpe = R('wpe.java');
t('wpe 6-field text block + j(i,i2)', wpe.includes('jt j(int') && (wpe.match(/public final/g)||[]).length>=5);
t('vle.G joe.d editing gate', vle.includes('joeVar.d'));
console.log('vle-selection-geom replay: ' + n + '/10 checks green');
