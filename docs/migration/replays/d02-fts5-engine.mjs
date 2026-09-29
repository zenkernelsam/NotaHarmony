// Phase 1010 — d6c FTS5 引擎实现 + b50 appsearch
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const d6c = readFileSync(D + 'd6c.java', 'utf8');
const b50 = readFileSync(D + 'b50.java', 'utf8');
const cfc = readFileSync(D + 'cfc.java', 'utf8');
const zec = readFileSync(D + 'zec.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('d6c: implements clc, klc field', d6c.includes('implements clc') && d6c.includes('public final klc a'));
t('d6c: engine name room-fts5', d6c.includes('public final String b = "room-fts5"'));
t('d6c.a: clear-all via cfc(1)', d6c.includes('new cfc(1)') && cfc.includes('DELETE FROM search_item'));
t('d6c.b: wkc->glc + write-side fold', d6c.includes('new glc(wkcVar.b.ordinal()') && d6c.includes('nnc.a(wkcVar.d)'));
t('d6c.b: batch via klc + J0', d6c.includes('klc klcVar = this.a') && d6c.includes('l96.J0(ef2Var, new ln(11'));
t('d6c.d: LIKE escape query', d6c.includes("foldedText LIKE ? ESCAPE '\\\\'") || d6c.includes('foldedText LIKE ?'));
t('d6c.e: no-op mof', /Object e\(ef2 ef2Var\)\s*\{\s*return mof\.a/.test(d6c));
t('d6c.g: FTS MATCH join', d6c.includes('search_fts MATCH ?'));
t('d6c.h: count via zec(13)', d6c.includes('new zec(13)') && zec.includes('SELECT COUNT(*) FROM search_item'));
t('d6c: getName returns b', /getName\(\)\s*\{\s*return this\.b/.test(d6c));
t('b50: implements clc', /class b50 implements clc/.test(b50));
t('b50: getName appsearch', b50.includes('return "appsearch"'));
console.log('fts5-engine replay: ' + n + '/12 checks green');
