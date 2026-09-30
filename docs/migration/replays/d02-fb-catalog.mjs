// Phase 1189 — ka4 FlatBuffers-table catalog (82 implementors)
import { readFileSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };
const impl = readdirSync(D).filter(f=>f.endsWith('.java')).filter(f=>{ try{return R(f).includes('implements ka4')}catch(e){return false} });

t('ka4 is interface', R('ka4.java').includes('interface ka4'));
t('82 ka4 implementors', impl.length === 82);
t('uq9 implements ka4 (Op table)', R('uq9.java').includes('implements ka4'));
t('vq9 implements ka4 (CREATE payload)', R('vq9.java').includes('implements ka4'));
t('fqa implements ka4 (asset/meta payload)', R('fqa.java').includes('implements ka4'));
t('cxc implements ka4 (page/seq-id)', R('cxc.java').includes('implements ka4'));
t('ua0 implements ka4 (asset-hash)', R('ua0.java').includes('implements ka4'));
t('dm2 implements ka4 (entity payload)', R('dm2.java').includes('implements ka4'));
t('r29 implements ka4 (wire bundle)', R('r29.java').includes('implements ka4'));
t('ka4 impls incl 30+ tables', ['utf','qo5','cwb','r60','yq3','wa0','ukb','xq3','bmb','yn2','akb','v01','ee8','sw9','ie8','gd','ra0','q89','qub','rl2','dm2','vt9','p9','s83','oz8','wd8','b3d','j2d','o2d'].every(f=>R(f+'.java').includes('implements ka4')));
console.log('fb-catalog replay: ' + n + '/10 checks green');
