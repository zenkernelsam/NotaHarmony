// Phase 919 — zq9 尾簇六表读图回归
// 证据：docs/migration/evidence/phase-919-zq9-tail.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const l2d = rd('l2d.java');
const ee8 = rd('ee8.java');
const mqf = rd('mqf.java');
const tl2 = rd('tl2.java');
const ud8 = rd('ud8.java');
const ra0 = rd('ra0.java');
const zq9 = rd('zq9.java');
const a79 = rd('a79.java');

ok(l2d.includes('SetMetadata(title=') && l2d.includes('pageBackground=') &&
   l2d.includes('handwritingLanguage=') && l2d.includes('alignTextToLines=') &&
   l2d.includes('defaultFontFamily=') && l2d.includes('defaultFontSize=') &&
   l2d.includes('layoutMode=') && l2d.includes('blockWrapSupport='),
  'l2d = SetMetadata 8 fields');
// setter type mix
ok(l2d.match(/Boolean j\(\)/) && l2d.match(/dz0 k\(\)/) &&
   l2d.match(/String l\(\)/) && l2d.match(/Float m\(\)/) &&
   l2d.match(/z2d n\(\)/) && l2d.match(/tv6 o\(\)/) &&
   l2d.match(/m2d p\(\)/) && l2d.match(/z2d q\(\)/),
  'l2d mixed raw+setter accessors');
// a79 register mirror
ok(a79.includes('alignTextToLines') || a79.includes('defaultFontFamily') ||
   a79.includes('layoutMode'), 'a79 doc registers mirrored');

ok(ee8.includes('ModifyPDFField(assetHash=') && ee8.includes('valueString=') &&
   ee8.includes('valueBoolean='), 'ee8 = ModifyPDFField dual-value');
ok(mqf.includes('UpdateCheckbox(textField=') && mqf.includes('location=') &&
   mqf.includes('isChecked='), 'mqf = UpdateCheckbox');
ok(tl2.includes('CreateComment(anchor=') && tl2.includes('z5c.t(this)'),
  'tl2 = CreateComment polymorphic anchor');
ok(ud8.includes('ModifyComment(comment=') && ud8.includes('resolved='),
  'ud8 = ModifyComment resolved flag');
ok(ra0.includes('AssetCloudPersisted(assetHash='), 'ra0 = AssetCloudPersisted');

ok(zq9.includes('l2d.class') && zq9.includes('haa.SET_METADATA'), 'l2d -> SET_METADATA');
ok(zq9.includes('ee8.class') && zq9.includes('haa.MODIFY_PDF_FIELD'), 'ee8 -> MODIFY_PDF_FIELD');
ok(zq9.includes('mqf.class') && zq9.includes('haa.UPDATE_CHECKBOX'), 'mqf -> UPDATE_CHECKBOX');
ok(zq9.includes('tl2.class') && zq9.includes('haa.CREATE_COMMENT'), 'tl2 -> CREATE_COMMENT');
ok(zq9.includes('ud8.class') && zq9.includes('haa.MODIFY_COMMENT'), 'ud8 -> MODIFY_COMMENT');
ok(zq9.includes('ra0.class') && zq9.includes('haa.ASSET_CLOUD_PERSISTED'),
  'ra0 -> ASSET_CLOUD_PERSISTED');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
