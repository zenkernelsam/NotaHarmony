// Phase 1233 — font loader + ReplacementSpan
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const lyb = R('lyb.java');
t('lyb ThreadLocal+WeakHashMap', lyb.includes('ThreadLocal a') && lyb.includes('WeakHashMap b'));
t('lyb a(Context,resId)', lyb.includes('Typeface a(Context context, int i)'));
t('lyb not-a-Font exception', lyb.includes('is not a Font'));
t('lyb klf resource util', lyb.includes('klf.b.c') || lyb.includes('klf.d'));
const ifj = R('ifj.java');
t('ifj Handler c() + e(Typeface)', ifj.includes('Handler c()') && ifj.includes('e(Typeface'));
const nlf = R('nlf.java');
t('nlf extends ReplacementSpan', nlf.includes('extends ReplacementSpan'));
t('nlf CharacterStyle spans', nlf.includes('getSpans(i, i2, CharacterStyle.class)'));
t('nlf ze.J Typeface', nlf.includes('zeVar.J'));
t('nlf getSize FontMetrics', nlf.includes('getSize') && nlf.includes('FontMetricsInt'));
const mac = R('mac.java');
t('mac Paint d,e + g9c', mac.includes('final Paint d') && mac.includes('final Paint e') && mac.includes('g9c a'));
console.log('font-loader replay: ' + n + '/10 checks green');
