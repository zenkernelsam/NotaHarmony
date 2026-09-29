// Phase 1009 — search_item 写入 + 高亮模型 + rects 恒 null
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const sq1 = readFileSync(D + 'sq1.java', 'utf8');
const klc = readFileSync(D + 'klc.java', 'utf8');
const alc = readFileSync(D + 'alc.java', 'utf8');
const q1f = readFileSync(D + 'q1f.java', 'utf8');
const glc = readFileSync(D + 'glc.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// sq1 binder
t('sq1: UPSERT with ON CONFLICT DO UPDATE', sq1.includes('ON CONFLICT(noteId, type, subId) DO UPDATE SET'));
t('sq1: 6-col bind order', sq1.includes('h0(1, str)') && sq1.includes('l(2, i2)') && sq1.includes('h0(3, str2)') && sq1.includes('h0(5, str4)'));
t('sq1: pageId nullable r(4)', sq1.includes('z7cVarD1.r(4)'));
t('sq1: rects nullable o(bArr,6)', sq1.includes('z7cVarD1.r(6)') && sq1.includes('z7cVarD1.o(bArr, 6)'));
// klc write DAO
t('klc.b: per-item tx UPSERT', klc.includes('l96.L0(ilcVar, klcVar2.a, false, true, new sq1('));
t('klc: rects bound null in call site', klc.includes('strA, (byte[]) null'));
t('klc: ro3 delete lambda', klc.includes('new ro3(str, i3, str2, 2)'));
// highlights models
t('alc: SearchHighlights{rects:List}', /class alc[\s\S]{0,60}public final List a/.test(alc) && alc.includes('SearchHighlights(rects='));
t('q1f: cache entry fields', q1f.includes('RichTextHighlightsCacheEntry(documentState=') && q1f.includes('textOrigin=') && q1f.includes('query=') && q1f.includes('rects='));
t('q1f: textOrigin via zn9.c (long cmp)', q1f.includes('zn9.c(this.b'));
// glc projection
t('glc: rects printed as null (projection)', glc.includes('Arrays.toString((byte[]) null)'));
t('glc: no rects field (5 fields only)', !/public final byte\[\]/.test(glc));
console.log('search-writes replay: ' + n + '/12 checks green');
