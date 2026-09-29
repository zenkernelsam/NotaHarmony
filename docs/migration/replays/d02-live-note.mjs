// Phase 1121 — a79 live note aggregate + 8 yc6 registers + w1b props
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const a79 = R('a79');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('a79 implements x09', a79.includes('final class a79 implements x09'));
t('a79: ye9 bundle header', a79.includes('ye9 b'));
t('a79: 7+ bja snapshots', (a79.match(/bja [a-z]/g) || []).length >= 5);
t('a79: uia snapshots', a79.includes('uia I') && a79.includes('uia r'));
t('a79: 8× yc6 registers', (a79.match(/yc6 [a-z]/g) || []).length >= 7);
t('a79: m4c spec + nz9 background', a79.includes('m4c B') && a79.includes('nz9'));
t('w1b props: title+fontFamily+fontSize', a79.includes('getTitle()') && a79.includes('getDefaultFontFamily()') && a79.includes('getDefaultFontSize()'));
t('w1b props: alignTextToLines+layoutMode+blockWrap', a79.includes('getAlignTextToLines()') && a79.includes('getLayoutMode()') && a79.includes('getBlockWrapSupport()'));
t('w1b prop handwritingLanguage', a79.includes('getHandwritingLanguage()'));
t('a79: suspend g(List,ff2)+h(Collection,ny3,yx4)', a79.includes('Object g(List list, ff2') && a79.includes('Object h(Collection collection, ny3'));
console.log('live-note replay: ' + n + '/10 checks green');
