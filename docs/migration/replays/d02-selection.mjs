// Phase 1181 — selection-state model (ktc sealed + 4 impls + cmb bounds)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ktc = R('ktc.java');
t('ktc interface', ktc.includes('interface ktc'));
t('ktc b() dispatch ftc/htc/etc/itc', ktc.includes('ftc') && ktc.includes('htc') && ktc.includes('etc') && ktc.includes('itc'));
t('ktc Set+getId(ttf)+i()', ktc.includes('Set c()') && ktc.includes('ttf getId()') && ktc.includes('boolean i()'));
const cmb = R('cmb.java');
t('cmb 4-float bounds', cmb.includes('float a') && cmb.includes('float d'));
t('cmb empty singleton e=(0,0,0,0)', cmb.includes('new cmb(0.0f, 0.0f, 0.0f, 0.0f)'));
t('itc implements ktc {qo5,ttf}', R('itc.java').includes('implements ktc') && R('itc.java').includes('qo5') && R('itc.java').includes('ttf'));
t('etc implements ktc {List,cmb}', R('etc.java').includes('implements ktc') && R('etc.java').includes('List') && R('etc.java').includes('cmb'));
t('ftc implements htc {2 cmb}', R('ftc.java').includes('implements htc') && (R('ftc.java').match(/cmb/g)||[]).length>=2);
t('htc extends ktc', R('htc.java').includes('extends ktc'));
t('pda marker iface', R('pda.java').includes('interface pda'));
console.log('selection replay: ' + n + '/10 checks green');
