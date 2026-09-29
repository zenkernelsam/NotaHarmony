// Phase 1033 — manifest handler taxonomy
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const yz = readFileSync(D + 'yz.java', 'utf8');
const a00 = readFileSync(D + 'a00.java', 'utf8');
const zz = readFileSync(D + 'zz.java', 'utf8');
const ug7 = readFileSync(D + 'ug7.java', 'utf8');
const gnd = readFileSync(D + 'gnd.java', 'utf8');
const tg7 = readFileSync(D + 'tg7.java', 'utf8');
const sg7 = readFileSync(D + 'sg7.java', 'utf8');
const wz = readFileSync(D + 'wz.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('yz: Appendable writer', yz.includes('implements Appendable') && /public final StringBuilder I;/.test(yz));
t('a00: CharSequence list', a00.includes('implements CharSequence') && /public final List I;/.test(a00));
t('zz: entry {a,b}', /public final Object a;/.test(zz) && /public final int b;/.test(zz));
t('ug7: abstract wz', ug7.includes('abstract class ug7 implements wz'));
t('ug7: cye+cqe accessors', ug7.includes('public abstract cye a()') && ug7.includes('public abstract cqe b()'));
t('gnd: dir handler', gnd.includes('implements wz') && /public final xoe a;/.test(gnd) && /public final long b;/.test(gnd));
t('tg7/sg7: asset handlers', tg7.includes('extends ug7') && sg7.includes('extends ug7'));
t('tg7/sg7: String+cqe', /public final String a;/.test(tg7) && /public final cqe b;/.test(tg7));
t('wz: iface', /interface wz/.test(wz));
const cu9 = readFileSync(D + 'cu9.java', 'utf8');
t('cu9 uses all types', cu9.includes('gndVar') && cu9.includes('tg7') && cu9.includes('sg7'));
console.log('manifest-handlers replay: ' + n + '/10 checks green');
