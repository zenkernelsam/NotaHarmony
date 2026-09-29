// Phase 1058 — enum sweep: im/iq0/n3a/oz9/xw9/y01/z4d/z90/zsa/ww9/t8a
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const im = R('im'), iq0 = R('iq0'), n3a = R('n3a'), oz9 = R('oz9'), xw9 = R('xw9'), y01 = R('y01'), z4d = R('z4d'), z90 = R('z90'), zsa = R('zsa'), ww9 = R('ww9'), t8a = R('t8a');
t('im: 5 anchor types', ['NONE((byte) 0)','CANVAS_ANCHOR((byte) 1)','TEXT_ANCHOR((byte) 2)','ENTITY_ANCHOR((byte) 3)','REPLY_ANCHOR((byte) 4)'].every(x => im.includes(x)));
t('iq0: sparse paper colors', iq0.includes('WHITE((byte) 13)') && iq0.includes('CREAM((byte) 1)') && iq0.includes('YELLOW((byte) 2)') && iq0.includes('BLACK((byte) 15)') && iq0.includes('TAN((byte) 6)') && iq0.includes('BLUE((byte) 7)'));
t('n3a: LINES/DOTS/GRID', n3a.includes('LINES((byte) 0)') && n3a.includes('DOTS((byte) 1)') && n3a.includes('GRID((byte) 2)'));
t('oz9: bookmark pair', oz9.includes('UNBOOKMARKED((byte) 0)') && oz9.includes('BOOKMARKED((byte) 1)'));
t('xw9: 3 PDF box modes', xw9.includes('DOWNSCALING_AND_MAX_BOX((byte) 0)') && xw9.includes('DOWNSCALING_AND_CROP_BOX((byte) 1)') && xw9.includes('FIT_AND_CROP_BOX((byte) 2)'));
t('y01: BEFORE/AFTER/START/END_OF_DOC', ['BEFORE((byte) 0)','AFTER((byte) 1)','START_OF_DOC((byte) 2)','END_OF_DOC((byte) 3)'].every(x => y01.includes(x)));
t('z4d: shape defs', z4d.includes('NONE((byte) 0)') && z4d.includes('LINE((byte) 1)') && z4d.includes('POLYGON((byte) 2)') && z4d.includes('NORMAL_SHAPE((byte) 3)'));
t('z90: NONE/SINGLE', z90.includes('NONE((byte) 0)') && z90.includes('SINGLE((byte) 1)'));
t('zsa: BITS_16/32', zsa.includes('BITS_16((byte) 0)') && zsa.includes('BITS_32((byte) 1)'));
t('ww9: STRING/BOOLEAN', ww9.includes('STRING((byte) 0)') && ww9.includes('BOOLEAN((byte) 1)'));
const t8aVals = ['ATTRIBUTED_CUBIC((byte) 0)','ATTRIBUTED_QUADRATIC((byte) 1)','ATTRIBUTED_LINE((byte) 2)','ATTRIBUTED_MOVE_TO((byte) 3)','NON_ATTRIBUTED_CUBIC((byte) 4)','NON_ATTRIBUTED_QUADRATIC((byte) 5)','NON_ATTRIBUTED_LINE((byte) 6)','NON_ATTRIBUTED_MOVE_TO((byte) 7)'];
t('t8a: 8 path-element types', t8aVals.every(x => t8a.includes(x)));
t('all 11 are byte enums', [im,iq0,n3a,oz9,xw9,y01,z4d,z90,zsa,ww9,t8a].every(s => s.includes('(byte)')));
console.log('enum-sweep replay: ' + n + '/12 checks green');
