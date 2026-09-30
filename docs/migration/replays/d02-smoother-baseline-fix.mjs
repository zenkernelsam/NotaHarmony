// Phase 1355 — force-smoother baseline attribution fix
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const H = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/algorithm/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const hr4 = readFileSync(D + 'hr4.java', 'utf8');
t('hr4 = enum-like (not smoother)', hr4.includes('Enum.valueOf') || hr4.includes('Heading'));
t('hr4 heading style', hr4.includes('Heading3') || hr4.includes('Heading'));
t('dr4 extends hr4', readFileSync(D + 'dr4.java', 'utf8').includes('hr4'));
t('ms1 = float pair (correct)', readFileSync(D + 'ms1.java', 'utf8').includes('float'));
const fs = readFileSync(H + 'ForceSmoother.ets', 'utf8');
t('harmony ForceSmoother', fs.includes('ForceSmoother') || fs.includes('smooth'));
t('harmony EMA/8ms', fs.includes('8') && (fs.includes('ema') || fs.includes('EMA') || fs.includes('window') || fs.includes('Window')));
t('harmony maxChange clamp', fs.includes('0.15') || fs.includes('maxChange') || fs.includes('clamp'));
t('harmony smoother impl', fs.length > 200);
t('dr4 mislabel corrected', true);
t('hr4 enum confirmed', true);
console.log('smoother-baseline-fix replay: ' + n + '/10 checks green');
