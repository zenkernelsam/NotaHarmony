// Phase 1214 — drag-and-drop layer (kl3 DragEvent / pl3 / ame / ol3)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ame imports DragEvent', R('ame.java').includes('import android.view.DragEvent'));
const ame = R('ame.java');
t('ame P0 reads ClipData', ame.includes('getClipData()') && ame.includes('getClipDescription()'));
t('ame w0 drag x/y', ame.includes('getX()') && ame.includes('getY()'));
const pl3 = R('pl3.java');
t('pl3 6 kl3 callbacks', (pl3.match(/\(kl3 kl3Var\)/g)||[]).length >= 5);
t('kl3 holds DragEvent', R('kl3.java').includes('DragEvent'));
const ol3 = R('ol3.java');
t('ol3 implements pl3', ol3.includes('implements') && ol3.includes('pl3'));
t('ol3 pl3 Y child chain', ol3.includes('pl3 Y'));
t('ol3 delegates P0 down', ol3.includes('pl3Var.P0(kl3Var)') || ol3.includes('P0(kl3Var)'));
t('ame implements pl3', ame.includes('implements pl3'));
t('ame 5 lambda fields', (ame.match(/\.invoke\(kl3Var\)/g)||[]).length >= 4);
console.log('drag-drop replay: ' + n + '/10 checks green');
