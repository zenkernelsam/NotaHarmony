// Phase 1031 — import pipeline (boh+zb5+gg1/qma)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const boh = readFileSync(D + 'boh.java', 'utf8');
const zb5 = readFileSync(D + 'zb5.java', 'utf8');
const gg1 = readFileSync(D + 'gg1.java', 'utf8');
const qma = readFileSync(D + 'qma.java', 'utf8');
const cu9 = readFileSync(D + 'cu9.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('boh.a: entry-hash builder', boh.includes('public static final jqe a(int i, int i2, int i3, int i4, int i5, boolean z)'));
t('boh.c: read conf string', boh.includes('public static String c(File file)'));
t('boh.d: unzip', boh.includes('public static void d(InputStream inputStream, File file)'));
t('zb5: importer iface', /interface zb5/.test(zb5) && zb5.includes('boolean b('));
t('gg1 implements zb5', gg1.includes('implements zb5'));
t('gg1: boh.d unzip + boh.c conf', gg1.includes('boh.d((InputStream) closeable, file)') && gg1.includes('boh.c(file)'));
t('gg1: no-conf IOException', gg1.includes('has no conf directory'));
t('gg1: pack cache put', gg1.includes('this.e.put(dc5Var2, strC)'));
t('qma implements zb5 + boh.c', qma.includes('implements zb5') && qma.includes('boh.c(new File(strA))'));
t('cu9: 3x boh.a manifest verify', (cu9.match(/boh\.a\(/g) || []).length >= 3);
console.log('import-pipeline replay: ' + n + '/10 checks green');
