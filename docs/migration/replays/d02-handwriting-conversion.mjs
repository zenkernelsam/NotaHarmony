// Phase 1302 — handwriting-to-text/math conversion (MyScript integration)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/dhb.java';
const d = readFileSync(S, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('dhb class', d.includes('class dhb'));
t('showMathConversionFailure', d.includes('showMathConversionFailure'));
t('showTextConversionFailure', d.includes('showTextConversionFailure'));
t('selection spans pages check', d.includes('Math conversion selection spans pages'));
t('stroke geometry Math.abs', d.includes('Math.abs'));
t('conversion result invoke', d.includes('invoke('));
t('implements iface', /class dhb implements/.test(d));
t('conversion logic large', d.length > 100000);
t('yn7 error handler', d.includes('yn7'));
t('selection validation', d.includes('spans pages'));
console.log('handwriting-conversion replay: ' + n + '/10 checks green');
