// Phase 1057 — Set× wrappers + ife/u76/qqe/akb types
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const z2d = R('z2d'), z1d = R('z1d'), g2d = R('g2d'), k2d = R('k2d'), v01 = R('v01'), ife = R('ife'), u76 = R('u76'), qqe = R('qqe'), akb = R('akb');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('z2d SetString', z2d.includes('SetString(value='));
t('z1d SetBool', z1d.includes('SetBool('));
t('g2d SetColor', g2d.includes('SetColor('));
t('k2d SetFloat', k2d.includes('SetFloat('));
t('v01 Boundary{location,type}', v01.includes('Boundary(location=') && v01.includes('type='));
t('v01: location→cxc', v01.includes('cxc'));
t('ife: 9 tape patterns', (ife.match(/\(byte\) \d+/g) || []).length === 9 && ['STRIPES','GRID','DOTS','PLAIN','STARS','FLOWERS','HEARTS','WAVES','CHECKERS'].every(x => ife.includes(x)));
t('u76: 4 peer tools', u76.includes('POINTER((byte) 0)') && u76.includes('PEN((byte) 1)') && u76.includes('HIGHLIGHTER((byte) 2)') && u76.includes('ERASER((byte) 3)'));
t('qqe TextSelection{anchor,focus}', qqe.includes('TextSelection(anchor=') && qqe.includes('focus='));
t('akb RecordingAsset{metadata}', akb.includes('RecordingAsset(metadata='));
t('wrappers extend cee/xwd+ka4', [z2d, z1d, g2d, k2d, v01, qqe, akb].every(s => (s.includes('extends cee') || s.includes('extends xwd')) && s.includes('implements ka4')));
t('ife/u76 byte enums', ife.includes('(byte) 8)') && u76.includes('(byte) 3)'));
console.log('wrapper-types replay: ' + n + '/12 checks green');
