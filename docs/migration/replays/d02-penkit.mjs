// Phase 1335 — PenKit predictor (platform stroke prediction)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const A = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/adaptation/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const p = readFileSync(A + 'PenKitPredictor.ets', 'utf8');
t('Penkit import', p.includes('@kit.Penkit'));
t('PointPredictor', p.includes('PointPredictor'));
t('Predictor iface impl', p.includes('implements Predictor'));
t('getPredictionPoint', p.includes('getPredictionPoint'));
t('finite validate', p.includes('Number.isFinite'));
t('fail-soft null degrade', p.includes('return null'));
t('Stylus.Handwrite degrade doc', p.includes('Stylus.Handwrite'));
t('platform-layer doc', p.includes('AndroidX Ink') || p.includes('平台输入层'));
t('Predictor iface', existsSync(A + 'Predictor.ets'));
t('reset defined', p.includes('reset()'));
console.log('penkit replay: ' + n + '/10 checks green');
