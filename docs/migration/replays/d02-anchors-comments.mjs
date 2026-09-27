// Phase 935 — 锚点多态 + 注释/字段 op 细节回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const im = rd('im.java');
ok(im.includes('NONE((byte) 0)') && im.includes('CANVAS_ANCHOR((byte) 1)') &&
   im.includes('TEXT_ANCHOR((byte) 2)') && im.includes('ENTITY_ANCHOR((byte) 3)') &&
   im.includes('REPLY_ANCHOR((byte) 4)'), 'im = AnchorKind 5 values');

const z5c = rd('z5c.java');
ok(z5c.includes('ka4 t(tl2 tl2Var)'), 'z5c.t = anchor dispatcher');
ok(z5c.match(/iOrdinal == 1[\s\S]{0,120}new hd1\(\)/), 'ordinal1 -> hd1 CanvasAnchor');
ok(z5c.match(/iOrdinal == 2[\s\S]{0,120}new lhe\(\)/), 'ordinal2 -> lhe TextAnchor');
ok(z5c.match(/iOrdinal == 3[\s\S]{0,120}new my3\(\)/), 'ordinal3 -> my3 EntityAnchor');
ok(z5c.match(/iOrdinal != 4[\s\S]{0,300}new cwb\(\)/), 'ordinal4 -> cwb ReplyAnchor (inverted guard)');

ok(rd('lhe.java').includes('TextAnchor(textField=') && rd('lhe.java').includes('selection='),
  'lhe = TextAnchor{textField,selection}');
ok(rd('cwb.java').includes('ReplyAnchor(root='), 'cwb = ReplyAnchor{root}');

const oz9 = rd('oz9.java');
ok(oz9.includes('UNBOOKMARKED((byte) 0)') && oz9.includes('BOOKMARKED((byte) 1)'), 'oz9 = BookmarkState');
ok(rd('tl2.java').includes('CreateComment(anchor='), 'tl2 = CreateComment');
ok(rd('ud8.java').includes('ModifyComment(comment=') && rd('ud8.java').includes('resolved='),
  'ud8 = ModifyComment');
ok(rd('ra0.java').includes('AssetCloudPersisted(assetHash='), 'ra0 = AssetCloudPersisted');
ok(rd('ee8.java').includes('ModifyPDFField(assetHash=') && rd('ee8.java').includes('valueBoolean='),
  'ee8 = ModifyPDFField');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
