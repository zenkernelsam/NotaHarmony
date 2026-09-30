// Phase 1198 — text-input/IME (a46 sink + nn6 KeyboardOptions + xvc)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const a46 = R('a46.java');
t('a46 interface', a46.includes('interface a46'));
t('a46 i(dle) edit sink', a46.includes('i(dle'));
t('a46 h(xvc) + j()→nn6', a46.includes('h(xvc') && a46.includes('nn6 j()'));
const nn6 = R('nn6.java');
t('nn6 KeyboardOptions toString', nn6.includes('KeyboardOptions'));
t('nn6 capitalization', nn6.includes('capitalization'));
t('nn6 autoCorrectEnabled', nn6.includes('autoCorrectEnabled'));
t('nn6 keyboardType+imeAction', nn6.includes('keyboardType') && nn6.includes('imeAction'));
t('nn6 showKeyboardOnFocus+hintLocales', nn6.includes('showKeyboardOnFocus') && nn6.includes('hintLocales'));
t('nn6 platformImeOptions', nn6.includes('platformImeOptions'));
t('xvc g(wvc,Object) iface', R('xvc.java').includes('interface xvc') && R('xvc.java').includes('g(wvc'));
console.log('keyboard replay: ' + n + '/10 checks green');
