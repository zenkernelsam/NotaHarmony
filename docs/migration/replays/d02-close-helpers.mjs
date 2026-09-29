// Phase 1101 — rh8.q closeFinally + x82.x delegate + ldj/k1a
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const rh8 = R('rh8'), x82 = R('x82'), ldj = R('ldj'), k1a = R('k1a'), c8d = R('c8d');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('rh8.q(AutoCloseable,Throwable)', rh8.includes('void q(AutoCloseable autoCloseable, Throwable th)'));
t('rh8.q: do6.x on throwable', rh8.includes('do6.x(autoCloseable)'));
t('rh8.q: s01.h addSuppressed', rh8.includes('s01.h(th, th2)'));
t('rh8.q: plain close path', rh8.includes('autoCloseable.close()'));
t('rh8.q: ExecutorService branch', rh8.includes('ExecutorService') && rh8.includes('isTerminated()'));
t('x82.x(cz8,fl6) delegate get', x82.includes('Object x(cz8 cz8Var, fl6 fl6Var)'));
t('ldj hex table', ldj.includes("'0', '1', '2'") && ldj.includes("'E', 'F'"));
t('ldj o22 statics', ldj.includes('new o22(') && ldj.includes('abstract class ldj'));
t('c8d extends ldj', c8d.includes('extends ldj'));
t('k1a = Serializable Pair{I,J}', k1a.includes('implements Serializable') && k1a.includes('Object I') && k1a.includes('Object J'));
console.log('close-helpers replay: ' + n + '/10 checks green');
