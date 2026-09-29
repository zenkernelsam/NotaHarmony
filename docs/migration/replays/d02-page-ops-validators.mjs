// Phase 1046 — page op payloads + ddg shared validators
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const ln2 = R('ln2'), ge8 = R('ge8'), ddg = R('ddg'), nz9 = R('nz9'), m2d = R('m2d');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ln2 CreatePage fields', ln2.includes('CreatePage(location=') && ln2.includes('background=') && ln2.includes('pageCount=') && ln2.includes('bookmarked='));
t('ln2: 0-page check', ln2.includes('Cannot create 0 pages'));
t('ln2: PDF count match', ln2.includes('Number of pages created must match the number of consumed pages in the PDF'));
t('ge8 ModifyPage fields', ge8.includes('ModifyPage(pages=') && ge8.includes('moveTo=') && ge8.includes('background=') && ge8.includes('lv2.Y(this)'));
t('ge8: 0-page check', ge8.includes('Must specify more than 0 pages'));
t('nz9 PageBackground{paper,pdf,rotation,size,margins}', nz9.includes('PageBackground(paper=') && nz9.includes('pdf=') && nz9.includes('rotation=') && nz9.includes('size=') && nz9.includes('margins='));
t('m2d SetPageBackground', m2d.includes('SetPageBackground(value='));
t('ddg.b: stylus azimuth/altitude', ddg.includes('Azimuth must be a unit vector') && ddg.includes('Altitude must be between zero and pi over 2'));
t('ddg.b: width/force finite nonneg', ddg.includes('Width invalid: Cannot be infinite') && ddg.includes('Width cannot be negative') && ddg.includes('Force invalid: Cannot be NaN'));
t('ddg.f: PDF cropbox per page', ddg.includes('Must specify a crop box size for each page consumed'));
t('ddg.g: PDF explicit size + margins + rotation', ddg.includes('PDF pages require an explicitly specified size') && ddg.includes('Cannot create margins larger than the page size') && ddg.includes('Cannot rotate to non cardinal directions'));
t('ddg.i: qed size nonneg', ddg.includes('width must be non-negative') && ddg.includes('height must be non-negative'));
console.log('page-ops-validators replay: ' + n + '/12 checks green');
