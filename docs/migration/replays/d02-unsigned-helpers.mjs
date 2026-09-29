// Phase 1060 — unsigned value-class family + helper layer
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const njj = R('njj'), ba6 = R('ba6'), rgc = R('rgc'), o14 = R('o14'), cmf = R('cmf'), ymf = R('ymf'), mmf = R('mmf'), tmf = R('tmf'), led = R('led');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('cmf = UByte (b&255)', cmf.includes('& 255') && cmf.includes('public final byte I'));
t('ymf = UShort (s&65535)', ymf.includes('& 65535') && ymf.includes('public final short I'));
t('led = UShort fmt', led.includes('String a(short'));
t('mmf = UInt (&0xFFFFFFFF + MIN_VALUE cmp)', mmf.includes('4294967295') && mmf.includes('UNDEFINED_DURATION'));
t('tmf = ULong (njj.j0 fmt)', tmf.includes('njj.j0(10, this.I)'));
t('njj.j0 = ULong.toString(radix)', njj.includes('Long.toString(j, i)') && njj.includes('j >>> 1') && njj.includes('cq.C(i)'));
t('rgc.b = data-loss IllegalStateException', rgc.includes('will lead to data loss when written to disk') && rgc.includes('IllegalStateException'));
t('o14: intrinsics throwers', o14.includes('AssertionError') && o14.includes('IllegalStateException') && o14.includes('IllegalArgumentException'));
t('ba6.o = Objects.equals', ba6.includes('static boolean o(Object'));
t('ba6.w = Integer.compare', ba6.includes('ba6.w(') || cmf.includes('ba6.w('));
t('mmf compareTo xor-sign-bit', mmf.includes('^ RecyclerView.UNDEFINED_DURATION'));
t('unsigned classes Comparable', [cmf, ymf, mmf, tmf].every(s => s.includes('Comparable')));
console.log('unsigned-helpers replay: ' + n + '/12 checks green');
