// Phase 1054 — l2d SetMetadata fields + z2d/tv6/dz0 wrappers
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const l2d = R('l2d'), z2d = R('z2d'), tv6 = R('tv6'), dz0 = R('dz0');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

['title=','pageBackground=','handwritingLanguage=','alignTextToLines=','defaultFontFamily=','defaultFontSize=','layoutMode=','blockWrapSupport='].forEach(f => assert.ok(l2d.includes(f), 'l2d missing ' + f));
t('l2d SetMetadata: all 8 fields', true);
t('l2d: title→z2d, pageBg→m2d, lang→z2d', l2d.includes('z2d q()') && l2d.includes('m2d p()') && l2d.includes('z2d n()'));
t('l2d: layoutMode→tv6, wrap→dz0', l2d.includes('tv6 o()') && l2d.includes('dz0 k()'));
t('l2d: alignTextToLines Boolean', l2d.includes('Boolean j()'));
t('l2d: fontFamily String + fontSize Float', l2d.includes('String l()') && l2d.includes('Float m()'));
t('z2d: SetString{value}', z2d.includes('SetString(value=') && z2d.includes('String j()'));
t('tv6: PAGED/PAGELESS', tv6.includes('PAGED((byte) 0)') && tv6.includes('PAGELESS((byte) 1)'));
t('dz0: 3 wrap modes incl LEGACY', dz0.includes('WRAP_ENABLED((byte) 0)') && dz0.includes('WRAP_DISABLED((byte) 1)') && dz0.includes('LEGACY_WRAP_ENABLED((byte) 2)'));
t('l2d: title/font validations (Ph1044)', l2d.includes('Title cannot be empty') && l2d.includes('256') && l2d.includes('greater than 0') && l2d.includes('> 30'));
t('l2d: ddg.g + template-PDF check', l2d.includes('ddg.g(') && l2d.includes('Template PDFs can only consume'));
t('tv6/dz0: enum arrays K/J', tv6.includes('tv6[]) K.clone()') && dz0.includes('dz0[]) J.clone()'));
console.log('setmetadata replay: ' + n + '/11 checks green');
