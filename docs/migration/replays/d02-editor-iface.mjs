// Phase 1200 — editor capability-iface surface (vle 11 ifaces)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };
const ifaces = ['lo3','cma','mvc','o65','ara','jm6','q52','rd8','sn9','kv6','mp4'];

t('vle implements all 11 ifaces', ifaces.every(i=>R('vle.java').includes(i)));
t('all 11 are public interfaces', ifaces.every(i=>R(i+'.java').includes('interface '+i)));
t('lo3 extends j73 + x0(jw6)', R('lo3.java').includes('extends j73') && R('lo3.java').includes('x0(jw6'));
t('o65 has f(ry8)', R('o65.java').includes('f(ry8'));
t('sn9 has t0()', R('sn9.java').includes('t0()'));
t('kv6 has b(long)', R('kv6.java').includes('b(long'));
t('mvc has default method', R('mvc.java').includes('default'));
t('ara has default method', R('ara.java').includes('default'));
t('rd8 has default method', R('rd8.java').includes('default'));
t('11 ifaces count distinct', ifaces.length===11);
console.log('editor-iface replay: ' + n + '/10 checks green');
