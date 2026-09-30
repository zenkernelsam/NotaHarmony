// Phase 1223 — text layout stack (vpe/fp0/wh8/upe/wpe = Compose named)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const vpe = R('vpe.java');
t('vpe a00+zqe+List+r93+rq4+nv6', vpe.includes('a00 a') && vpe.includes('zqe b') && vpe.includes('r93 g') && vpe.includes('rq4 i') && vpe.includes('nv6 h'));
t('vpe maxLines+softWrap+constraints', vpe.includes('int d') && vpe.includes('boolean e') && vpe.includes('long j'));
const fp0 = R('fp0.java');
t('fp0 MultiParagraphIntrinsics ctor', fp0.includes('fp0(a00 a00Var, zqe zqeVar, List') && fp0.includes('r93 r93Var, rq4'));
const wh8 = R('wh8.java');
t('wh8 fp0 intrinsics', wh8.includes('fp0 a'));
t('wh8 paragraph ArrayLists', wh8.includes('ArrayList g') && wh8.includes('ArrayList h'));
t('wh8 maxLines+lineCount', wh8.includes('int b') && wh8.includes('int f'));
const upe = R('upe.java');
t('upe TextPaint+TruncateAt+Layout', upe.includes('TextPaint a') && upe.includes('TruncateAt b') && upe.includes('Layout f'));
const wpe = R('wpe.java');
t('wpe vpe+wh8+size+baselines', wpe.includes('vpe a') && wpe.includes('wh8 b') && wpe.includes('long c') && wpe.includes('float d') && wpe.includes('float e'));
t('wpe placeholder rects', wpe.includes('ArrayList f'));
t('wh8 offset→paragraph n/m', wh8.includes('void n(int') || wh8.includes('int m(int') || wh8.includes(' n('));
console.log('text-layout-stack replay: ' + n + '/10 checks green');
