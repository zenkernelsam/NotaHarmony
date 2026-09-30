// Phase 1185 — text-span layer (nlf ReplacementSpan + typeface cache)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const nlf = R('nlf.java');
t('nlf extends ReplacementSpan', nlf.includes('extends ReplacementSpan'));
t('nlf draw(Canvas,CharSequence,...)', nlf.includes('draw(Canvas') && nlf.includes('CharSequence'));
t('nlf FontMetricsInt', nlf.includes('FontMetricsInt'));
t('nlf TextPaint', nlf.includes('TextPaint'));
t('nlf Paint param in draw', nlf.includes('Paint paint'));
const lyb = R('lyb.java');
t('lyb typeface cache ThreadLocal+WeakHashMap', lyb.includes('ThreadLocal') && lyb.includes('WeakHashMap'));
t('lyb abstract class', lyb.includes('abstract class lyb'));
const ifj = R('ifj.java');
t('ifj typeface style handler', ifj.includes('Typeface') && ifj.includes('b(Typeface'));
t('ifj a(int) style + c() Handler', ifj.includes('a(int') && ifj.includes('Handler'));
t('mac Typeface DEFAULT holder', R('mac.java').includes('Typeface.DEFAULT'));
console.log('text-span replay: ' + n + '/10 checks green');
