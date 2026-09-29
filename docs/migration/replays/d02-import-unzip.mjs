// Phase 1030 — import unzip + zip-slip guard
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const boh = readFileSync(D + 'boh.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('boh: abstract class', /abstract class boh/.test(boh));
t('boh: ZipInputStream+Buffered', boh.includes('ZipInputStream') && boh.includes('BufferedInputStream'));
t('boh: getNextEntry loop', boh.includes('getNextEntry()'));
t('boh: canonical path', boh.includes('getCanonicalFile()'));
t('zip-slip guard: ba6.o+svd.n0', boh.includes('ba6.o(canonicalFile2, canonicalFile)') && boh.includes('svd.n0('));
t('zip-slip IOException', boh.includes('Zip entry escapes target directory'));
t('isDirectory branch', boh.includes('isDirectory()'));
t('fag.F/G mkdir+touch', boh.includes('fag.F(') && boh.includes('fag.G('));
t('l96.i0 8KB copy', boh.includes('l96.i0(zipInputStream, fileOutputStream, 8192)'));
t('o22 lambda table', boh.includes('new o22(new y22(27), false'));
console.log('import-unzip replay: ' + n + '/10 checks green');
