// Phase 1249 — ol3/pl3/kl3/ame drag-drop dispatch
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ol3 = R('ol3.java');
t('ol3 extends od8 vff+pl3+kv6', ol3.includes('extends od8 implements vff, pl3, kv6'));
t('ol3 X nested + pl3 Y target', ol3.includes('ol3 X') && ol3.includes('pl3 Y'));
t('ol3 F(kl3) dragStarted', ol3.includes('void F(kl3'));
t('ol3 P0(kl3) tree dispatch', ol3.includes('boolean P0(kl3') && ol3.includes('ol3Var.P0(kl3Var)'));
t('ol3 k0/b/s lifecycle', ol3.includes('k0(kl3') && ol3.includes('Object s()'));
const pl3 = R('pl3.java');
t('pl3 P0(kl3) iface', pl3.includes('boolean P0(kl3'));
t('pl3 w0 default', pl3.includes('void w0(kl3'));
const kl3 = R('kl3.java');
t('kl3 DragEvent a', kl3.includes('DragEvent a'));
const ame = R('ame.java');
t('ame 5-lambda pl3', ame.includes('implements pl3') && ame.includes('zy7'));
t('ame P0 reads ClipData', ame.includes('getClipData()'));
console.log('drag-dispatch replay: ' + n + '/10 checks green');
