// Phase 1110 — iwc live text-seq CRDT + y51 lookup + bxc spec
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const iwc = R('iwc'), bxc = R('bxc'), y51 = R('y51'), bka = R('bka'), g5c = R('g5c');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('iwc(bxc) spec→live ctor', iwc.includes('iwc(bxc bxcVar)'));
t('iwc: wia store from bxc.c.a()', iwc.includes('bxcVar.c.a()'));
t('iwc: dual gja builders', iwc.includes('bxcVar.h.builder()') && iwc.includes('bxcVar.g.builder()'));
t('iwc: y51 adapter on wia', iwc.includes('new y51(wiaVarA)'));
t('iwc: 4× hr5 anchors', iwc.includes('hr5 t') && iwc.includes('hr5 u') && iwc.includes('hr5 v') && iwc.includes('hr5 w'));
t('iwc: xgb timestamp + al2 tombstone', iwc.includes('xgb q') && iwc.includes('al2 l'));
t('bxc implements jxc,bf0', bxc.includes('implements jxc, bf0'));
t('y51 extends g8d w/ wia', y51.includes('extends g8d') && y51.includes('wia I'));
t('y51.a(long)→wia.c.h', y51.includes('this.I.c.h(j)'));
t('bka Collection + g5c y3', bka.includes('implements Collection') && g5c.includes('extends y3'));
console.log('iwc-live replay: ' + n + '/10 checks green');
