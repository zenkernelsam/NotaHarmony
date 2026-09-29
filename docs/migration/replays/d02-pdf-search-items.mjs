// Phase 1006 — kw1 case-6 PDF 资产搜索项生成
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const kw1 = readFileSync(D + 'kw1.java', 'utf8');
const aa6 = readFileSync(D + 'aa6.java', 'utf8');
const lvd = readFileSync(D + 'lvd.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const case6 = kw1.slice(kw1.indexOf('case 6:'), kw1.indexOf('case 7:') > 0 ? kw1.indexOf('case 7:') : kw1.length);
t('kw1 case6: iterates page map + ua0', case6.includes('LinkedHashMap') && case6.includes('ua0'));
t('kw1 case6: PDF text via aa6.E0 cap 50000', case6.includes('aa6.E0(bx9Var, 50000)'));
t('kw1 case6: lvd.b1 truncation on both paths', case6.includes('lvd.b1(50000'));
t('kw1 case6: \\n\\n merge separator', case6.includes('"\\n\\n"'));
t('kw1 case6: wkc w/ me2.P=PDF + ua0_idx subId', /new wkc\(ttfVar, me2\.P, ua0Var \+ "_" \+ iIntValue4/.test(case6));
t('kw1 case6: pageId via z5c.Z(cxc)', case6.includes('z5c.Z(cxcVar)'));
// helpers
t('aa6.E0: bx9->String extract signature', /String E0\(bx9 bx9Var, int i\)/.test(aa6));
t('lvd.b1: prefix truncation', /String b1\(int i, String str\)/.test(lvd));
t('lvd.b1: substring(0,min(n,len)) + neg-guard', /b1\(int i, String str\)[\s\S]{0,400}str\.substring\(0, i\)/.test(lvd) && lvd.includes('is less than zero'));
// wkc me2.P == PDF ordinal sanity
const me2 = readFileSync(D + 'me2.java', 'utf8');
t('me2.P = PDF (ordinal 6)', me2.includes('new me2("PDF", 6)'));
console.log('pdf-search-items replay: ' + n + '/10 checks green');
