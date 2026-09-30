// Phase 1202 — t76 gesture-event family (12 impl + hwa timed sub-family)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('t76 marker iface', R('t76.java').includes('public interface t76'));
t('rj5/zo4/mn3/ll3 empty markers', ['rj5','zo4','mn3','ll3'].every(f=>R(f+'.java').includes('implements t76')));
t('sj5 wraps rj5', R('sj5.java').includes('rj5 a') || R('sj5.java').includes('rj5 '));
t('ap4 wraps zo4', R('ap4.java').includes('zo4 a'));
t('nn3+ln3 wrap mn3', R('nn3.java').includes('mn3 a') && R('ln3.java').includes('mn3 a'));
t('ml3 wraps ll3', R('ml3.java').includes('ll3 a'));
t('hwa extends t76', R('hwa.java').includes('extends t76'));
t('fwa timed {long}', R('fwa.java').includes('long a'));
t('gwa+ewa wrap fwa', R('gwa.java').includes('fwa a') && R('ewa.java').includes('fwa a'));
const ww0 = R('ww0.java');
t('ww0 haptic-stack add/remove + weights', ww0.includes('arrayList.add') && ww0.includes('arrayList.remove') && ww0.includes('0.08f') && ww0.includes('0.16f'));
console.log('t76-events replay: ' + n + '/10 checks green');
