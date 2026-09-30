// Phase 1232 — 360 geometry / stereo mesh structures
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const q0b = R('q0b.java');
t('q0b UV matrix i mono', q0b.includes('{1.0f, 0.0f, 0.0f, 0.0f, -1.0f, 0.0f, 0.0f, 1.0f, 1.0f}'));
t('q0b UV matrix j top-bottom', q0b.includes('-0.5f'));
t('q0b UV matrix k side-by-side', q0b.includes('{0.5f, 0.0f'));
t('q0b r71 b mesh + xaf c', q0b.includes('r71 b') && q0b.includes('xaf c'));
t('q0b b(p0b) stereo valid', q0b.includes('b(p0b'));
const p0b = R('p0b.java');
t('p0b stereo pair o0b a,b + type c', p0b.includes('o0b a') && p0b.includes('int c') && p0b.includes('o0bVar == o0bVar2'));
const o0b = R('o0b.java');
t('o0b r71[] eye meshes', o0b.includes('r71[] a'));
const m40 = R('m40.java');
t('m40 mode-3 K/L float16 + r71 M', m40.includes('new float[16]') && m40.includes('new r71(8, false)'));
t('m40 implements w94,jwi', m40.includes('implements w94, jwi'));
t('m40 K baseline + M queue', m40.includes('this.M = new r71(8, false)'));
console.log('360-geometry replay: ' + n + '/10 checks green');
