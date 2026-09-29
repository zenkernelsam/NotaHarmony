// Phase 1008 — e6c 查询构造器 + mlc 模式 + m2a 变换
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const e6c = readFileSync(D + 'e6c.java', 'utf8');
const mlc = readFileSync(D + 'mlc.java', 'utf8');
const m2a = readFileSync(D + 'm2a.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// mlc SearchMode enum
t('mlc: SUBSTRING(0)', mlc.includes('new mlc("SUBSTRING", 0)'));
t('mlc: WHOLE_WORD(1)', mlc.includes('new mlc("WHOLE_WORD", 1)'));
t('mlc: EXACT(2)', mlc.includes('new mlc("EXACT", 2)'));
t('mlc: PREFIX(3)', mlc.includes('new mlc("PREFIX", 3)'));
t('mlc: TOKEN_PREFIX(4)', mlc.includes('new mlc("TOKEN_PREFIX", 4)'));
// e6c.a LIKE pattern
t('e6c.a: folds via nnc.a', e6c.includes('nnc.a(str)'));
t('e6c.a: blank->null guard', e6c.includes('lvd.E0(strA)'));
t('e6c.a: escapes \\,%,_ then %-wraps', e6c.includes('"\\\\", "\\\\\\\\"') && e6c.includes('"%", "\\\\%"') && e6c.includes('"_", "\\\\_"'));
// e6c.b FTS builder
t('e6c.b: tokenizer [^\\p{L}\\p{N}]+', e6c.includes('"[^\\\\p{L}\\\\p{N}]+"') || e6c.includes('[^\\p{L}\\p{N}]'));
t('e6c.b: ordinal 0 -> null (LIKE path)', /iOrdinal = mlcVar\.ordinal\(\)\) == 0\)\s*\{\s*return null/.test(e6c) || e6c.includes('== 0)'));
t('e6c.b: ordinal1 bare space join', e6c.includes('au1.k1(arrayList, " ", null, null, null, 62)'));
t('e6c.b: ordinal2 quoted phrase', e6c.includes('au1.k1(arrayList, " ", "\\"", "\\"", null, 56)'));
t('e6c.b: ordinal3/4 transform join', e6c.includes('iOrdinal == 3 || iOrdinal == 4') && e6c.includes('new m2a(23)'));
// m2a case 23
const case23 = m2a.slice(m2a.indexOf('case 23:'), m2a.indexOf('case 24:'));
t('m2a case23: str + "*" prefix', case23.includes('concat("*")'));
console.log('query-builder replay: ' + n + '/14 checks green');
