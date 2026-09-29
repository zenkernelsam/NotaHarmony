// Phase 1004 — SearchItem 模型 + nnc 折叠 + me2 类型
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const wkc = readFileSync(D + 'wkc.java', 'utf8');
const me2 = readFileSync(D + 'me2.java', 'utf8');
const nnc = readFileSync(D + 'nnc.java', 'utf8');
const ba6 = readFileSync(D + 'ba6.java', 'utf8');
const glc = readFileSync(D + 'glc.java', 'utf8');
const d6c = readFileSync(D + 'd6c.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// wkc model
t('wkc: {ttf,me2,String c/d/e,f=key}', wkc.includes('public final ttf a') && wkc.includes('public final me2 b') && wkc.includes('public final String f'));
t('wkc: key = ba6.s(noteId,type,subId)', wkc.includes('ba6.s(ttfVar, me2Var, str)'));
// me2 enum
t('me2: TITLE', me2.includes('new me2("TITLE", 0)'));
t('me2: MAIN_BODY_TEXT', me2.includes('new me2("MAIN_BODY_TEXT", 1)'));
t('me2: TEXT_BLOCK', me2.includes('new me2("TEXT_BLOCK", 2)'));
t('me2: INK', me2.includes('new me2("INK", 3)'));
t('me2: RECORDING_TRANSCRIPT', me2.includes('new me2("RECORDING_TRANSCRIPT", 4)'));
t('me2: IMAGE', me2.includes('new me2("IMAGE", 5)'));
t('me2: PDF', me2.includes('new me2("PDF", 6)'));
// nnc fold
t('nnc.a: Mn-strip regex', nnc.includes('"\\\\p{Mn}+"'));
t('nnc.a: NFD normalize', nnc.includes('Normalizer.normalize(str, Normalizer.Form.NFD)'));
t('nnc.a: ROOT lowercase', nnc.includes('toLowerCase(locale)'));
t('nnc.b: 16-entry fold map (ß->ss..ﬄ->ffl)', nnc.includes('(char) 223, "ss"') && nnc.includes('(char) 64260, "ffl"'));
// ba6.s key
t('ba6.s: {noteId} {ordinal} {subId} join', /return ttfVar\.toString\(\) \+ " " \+ me2Var\.ordinal\(\) \+ " " \+ str/.test(ba6));
// glc row + write-time fold
t('glc: toString SearchItem fields', glc.includes('SearchItem(id=0, noteId=') && glc.includes(', foldedText=') && glc.includes(', rects='));
t('d6c: write-side fold nnc.a(wkc.d)', d6c.includes('nnc.a(wkcVar.d)'));
console.log('search-item-model replay: ' + n + '/16 checks green');
