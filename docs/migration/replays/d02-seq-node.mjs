// Phase 1112 — f8d node + g8d long-map + bxc spec fields
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const f8d = R('f8d'), g8d = R('g8d'), bxc = R('bxc'), y51 = R('y51');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('f8d node fields', f8d.includes('short a') && f8d.includes('long c') && f8d.includes('qwc d') && f8d.includes('List e'));
t('f8d.a(hr5,int) anchor access', f8d.includes('a(hr5 hr5Var, int i)'));
t('f8d ctor 5-arg', f8d.includes('f8d(short s, int i, long j, qwc qwcVar, List list)'));
t('g8d abstract Map,ik6', g8d.includes('abstract class g8d implements Map, ik6'));
t('g8d: a(long)→f8d + b()→int', g8d.includes('f8d a(long j)') && g8d.includes('int b()'));
t('y51 adapts wia→g8d', y51.includes('extends g8d') && y51.includes('wia I'));
t('bxc implements jxc,bf0', bxc.includes('implements jxc, bf0'));
t('bxc: sia index + dual hja', bxc.includes('sia c') && bxc.includes('hja g') && bxc.includes('hja h'));
t('bxc: k5c + kia + cl2', bxc.includes('k5c b') && bxc.includes('kia e') && bxc.includes('cl2 f'));
t('bxc static sia v', bxc.includes('sia v'));
console.log('seq-node replay: ' + n + '/10 checks green');
