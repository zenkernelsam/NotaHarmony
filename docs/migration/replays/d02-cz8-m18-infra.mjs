// Phase 959 — cz8 复位池 + x82.x 委托 + m18 ListBuilder/量化
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const cz8 = readFileSync(`${ROOT}/cz8.java`, 'utf8');
const x82 = readFileSync(`${ROOT}/x82.java`, 'utf8');
const m18 = readFileSync(`${ROOT}/m18.java`, 'utf8');
const th7 = readFileSync(`${ROOT}/th7.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// cz8 = ThreadLocal with per-get reset
ok(/class cz8 extends ThreadLocal/.test(cz8), 'cz8 extends ThreadLocal');
ok(/public final Function0 a;[\s\S]{0,80}public final ix4 b;/.test(cz8), 'cz8 = {a=factory, b=reset}');
ok(/initialValue\(\)[\s\S]{0,60}this\.a\.invoke\(\)/.test(cz8), 'cz8: initialValue = factory');
ok(/Object obj = super\.get\(\);\s*this\.b\.invoke\(obj\);/.test(cz8), 'cz8: get = get + reset');

// x82.x = delegate acquire (raw get + manual reset)
ok(/static final Object x\(cz8 cz8Var, fl6 fl6Var\)/.test(x82), 'x82.x = delegate getValue');
ok(/cz8Var\.a\(\);[\s\S]{0,80}cz8Var\.b\.invoke\(objA\)/.test(x82), 'x82.x: a() + b.invoke');

// m18.S/E ListBuilder pair
ok(/static th7 S\(\)[\s\S]{0,60}new th7\(10\)/.test(m18), 'm18.S = th7(10) builder');
ok(/th7Var\.i\(\);[\s\S]{0,30}th7Var\.K = true;[\s\S]{0,60}th7\.L/.test(m18), 'm18.E = checkIsMutable + seal + empty->L');
ok(/Math\.round\(f\)/.test(m18) && /Cannot round NaN/.test(m18), 'm18.y0 = round + NaN guard');

// th7 = Kotlin ListBuilder
ok(/class th7 extends u4 implements RandomAccess/.test(th7), 'th7 = u4+RandomAccess ListBuilder');
ok(/public boolean K;/.test(th7), 'th7.K = isReadOnly flag');
ok(/static \{[\s\S]{0,100}new th7\(0\)[\s\S]{0,80}K = true;[\s\S]{0,40}L = th7Var/.test(th7), 'th7.L = sealed empty singleton');

// x82 UTF-8 surrogate pair formula
ok(/\(\(b2 & 7\) << 18\) \| \(\(b3 & 63\) << 12\) \| \(\(b4 & 63\) << 6\) \| \(b5 & 63\)/.test(x82), 'x82.y: 4-byte bit assembly');
ok(/\(i3 >>> 10\) \+ 55232/.test(x82) && /\(i3 & 1023\) \+ 56320/.test(x82), 'x82.y: surrogate pair 0xD7C0/0xDC00');

console.log(`\ncz8-m18-infra replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
