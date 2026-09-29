// Phase 1056 — value types: fqa/qed/bmb/vy7/hu1/k3a/tmf
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const fqa = R('fqa'), qed = R('qed'), bmb = R('bmb'), vy7 = R('vy7'), hu1 = R('hu1'), k3a = R('k3a'), tmf = R('tmf');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('fqa Point{x,y}', fqa.includes('Point(x=') && fqa.includes('y=') && fqa.includes('extends xwd'));
t('qed Size{width,height} swapped accessors', qed.includes('Size(width=') && qed.includes('height=') && qed.includes('extends xwd'));
t('bmb Rect{origin,size}', bmb.includes('Rect(origin=') && bmb.includes('size='));
t('vy7 Margins{top,bottom,left,right}', vy7.includes('Margins(top=') && vy7.includes('bottom=') && vy7.includes('left=') && vy7.includes('right='));
t('vy7: non-negative check', vy7.includes('Margins cannot be negative'));
t('vy7: float reads via getFloat', vy7.includes('this.J.getFloat(this.I + 12)') && vy7.includes('getFloat(this.I)'));
t('hu1 Color{bitsR,G,B,A} byte×4', hu1.includes('Color(bitsR=') && hu1.includes('bitsG=') && hu1.includes('bitsB=') && hu1.includes('bitsA=') && hu1.includes('cmf.a('));
t('hu1: 4 byte accessors', (hu1.match(/public final byte [c-f]\(\)/g) || []).length === 4);
t('k3a Paper 6 fields', k3a.includes('Paper(flair=') && k3a.includes('flairSpacing=') && k3a.includes('flairBleeds=') && k3a.includes('flairCentered=') && k3a.includes('backgroundColor=') && k3a.includes('legacyPaperIndex='));
t('k3a: alpha==1 rule', k3a.includes('Paper background colors must be alpha == 1'));
t('tmf: long value + j0 fmt', tmf.includes('public final long I') && tmf.includes('njj.j0(10, this.I)') && tmf.includes('implements Comparable'));
t('k3a is cee table not struct', k3a.includes('extends cee') && !k3a.includes('extends xwd'));
console.log('value-types replay: ' + n + '/12 checks green');
