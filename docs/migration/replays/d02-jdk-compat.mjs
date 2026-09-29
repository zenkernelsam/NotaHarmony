// Phase 1104 — do6.x JDK7 close + s01.h addSuppressed compat
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const do6 = R('do6'), s01 = R('s01');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('do6.x(AutoCloseable) synthetic', do6.includes('void x(AutoCloseable autoCloseable)'));
t('do6.x: instanceof AutoCloseable→close', do6.includes('autoCloseable instanceof AutoCloseable') && do6.includes('autoCloseable.close()'));
t('do6.x: ExecutorService branch', do6.includes('executorService.shutdown()'));
t('do6.x: awaitTermination(1,DAYS)', do6.includes('awaitTermination(1L, TimeUnit.DAYS)'));
t('do6.x: interrupt→shutdownNow', do6.includes('shutdownNow()'));
t('do6.x: commonPool skip', do6.includes('ForkJoinPool.commonPool()'));
t('s01.h(th,th2)', s01.includes('void h(Throwable th, Throwable th2)'));
t('s01.h: th!=th2 dedupe', s01.includes('th != th2'));
t('s01.h: ua6.a SDK gate ≥19', s01.includes('ua6.a') && s01.includes('>= 19'));
t('s01.h: addSuppressed + qla.a reflect fallback', s01.includes('addSuppressed(th2)') && s01.includes('qla.a'));
console.log('jdk-compat replay: ' + n + '/10 checks green');
