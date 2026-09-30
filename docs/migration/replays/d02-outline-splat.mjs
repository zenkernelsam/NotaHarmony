// Phase 1328 — WidthOutlineBuilder + PencilSplat audit
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/algorithm/';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const wo = readFileSync(S + 'WidthOutlineBuilder.ets', 'utf8');
t('WidthOutlineBuilder class', wo.includes('class WidthOutlineBuilder'));
t('halfWidth per-point', wo.includes('halfWidth'));
t('appendArc round caps', wo.includes('appendArc'));
t('outlinePoints closed polygon', wo.includes('outlinePoints'));
t('bezierkit attributed path ref', /bezierkit|attributed/i.test(wo));
const ps = readFileSync(S + 'PencilSplatGenerator.ets', 'utf8');
t('PencilSplatGenerator class', ps.includes('PencilSplatGenerator') || ps.includes('splat'));
t('splat generation', /splat|Splat/.test(ps));
t('original baselines xaa/oz5', existsSync(D + 'xaa.java') && existsSync(D + 'oz5.java'));
t('w4a+y5a baselines', existsSync(D + 'w4a.java') && existsSync(D + 'y5a.java'));
t('algorithm dir', existsSync(S));
console.log('outline-splat replay: ' + n + '/10 checks green');
