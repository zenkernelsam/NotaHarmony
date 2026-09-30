// Phase 1271 — ywb/bw8/jwb/d34 Volley HTTP stack
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ywb = R('ywb.java');
t('ywb RequestQueue', ywb.includes('AtomicInteger a') && ywb.includes('HashSet b'));
t('ywb cache+network queues', (ywb.match(/PriorityBlockingQueue/g)||[]).length >= 2);
t('ywb bw8[] dispatchers', ywb.includes('bw8[] h'));
t('ywb eg3+ub cache/delivery', ywb.includes('eg3 e') && ywb.includes('ub g'));
const bw8 = R('bw8.java');
t('bw8 extends Thread', bw8.includes('extends Thread'));
t('bw8 network-http-complete marker', bw8.includes('network-http-complete'));
const jwb = R('jwb.java');
t('jwb Request Comparable', jwb.includes('implements Comparable'));
t('jwb deliverResponse/Error', jwb.includes('deliverResponse') && jwb.includes('deliverError'));
t('jwb addMarker+cancel', jwb.includes('addMarker') && jwb.includes('cancel'));
const d34 = R('d34.java');
t('d34 delivery runnable', d34.includes('implements Runnable') && d34.includes('VolleyError'));
console.log('volley replay: ' + n + '/10 checks green');
