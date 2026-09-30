// Phase 1263 — ype/wpe/wh8/upe/vpe/fp0 text-layout stack
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const vpe = R('vpe.java');
t('vpe a00+zqe+rq4 TextLayoutInput', vpe.includes('a00 a') && vpe.includes('zqe b') && vpe.includes('rq4 i'));
t('vpe nv6 LayoutDirection+r93', vpe.includes('nv6 h') && vpe.includes('r93 g'));
const fp0 = R('fp0.java');
t('fp0 MultiParagraphIntrinsics', fp0.includes('a00 a00Var, zqe zqeVar'));
const wh8 = R('wh8.java');
t('wh8 MultiParagraph fp0+lineCount', wh8.includes('fp0 a') && wh8.includes('int b'));
t('wh8 ArrayList g,h paragraphs', wh8.includes('ArrayList g') && wh8.includes('ArrayList h'));
const upe = R('upe.java');
t('upe TextPaint+StaticLayout', upe.includes('TextPaint a') && upe.includes('StaticLayout'));
t('upe TruncateAt ellipsis', upe.includes('TruncateAt b'));
const wpe = R('wpe.java');
t('wpe TextLayoutResult vpe+wh8', wpe.includes('vpe a') && wpe.includes('wh8 b'));
t('wpe a(i)->kxb b(i)->cmb', wpe.includes('kxb a(int i)') && wpe.includes('cmb b(int i)'));
const ype = R('ype.java');
t('ype yme+p6a+q21 holder', ype.includes('yme a') && ype.includes('p6a c') && ype.includes('q21 g'));
console.log('text-layout replay: ' + n + '/10 checks green');
