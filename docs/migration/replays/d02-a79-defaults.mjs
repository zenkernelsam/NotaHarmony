// Phase 1155 — a79 static defaults + 7 metadata props
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const a79 = R('a79');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('a79.N = qed page size', a79.includes('static final qed N'));
t('a79.N = apb.h(612,792) US Letter', a79.includes('apb.h(612.0f, 792.0f)'));
t('a79.O = vy7 margins fsi.f(36×4)', a79.includes('static final vy7 O') && a79.includes('fsi.f(36.0f, 36.0f, 36.0f, 36.0f)'));
t('a79.P = N.d()/8.5 pt/inch', a79.includes('static final float P') && a79.includes('qedVarH.d() / 8.5f'));
t('a79.Q = nz9 default bg', a79.includes('static final nz9 Q'));
t('a79.R = w69 default', a79.includes('static final w69 R'));
t('a79.L = er6(3) companion', a79.includes('static final er6 L = new er6(3)'));
t('a79.M 7 w1b metadata props', a79.includes('"title"') && a79.includes('"defaultFontFamily"') && a79.includes('"handwritingLanguage"'));
t('a79 layoutMode+blockWrapSupport LayoutMode schema', a79.includes('flatbuffers/LayoutMode') && a79.includes('flatbuffers/BlockWrapSupport'));
t('a79.a copy-with mega (27-arg)', a79.includes('a79 a(a79 a79Var, kia kiaVar'));
console.log('a79-defaults replay: ' + n + '/10 checks green');
