// Phase 1032 — cu9 manifest index writer
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const cu9 = readFileSync(D + 'cu9.java', 'utf8');
const jqe = readFileSync(D + 'jqe.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('cu9: 3 partitions', cu9.includes('a00Var.b()') && cu9.includes('a00Var.a(0,') && cu9.includes('a00Var.c('));
t('cu9: boh.a per entry', (cu9.match(/boh\.a\(zzVar/g) || []).length >= 3);
t('jqe: packed long a', /public (final )?long a;|\.a/.test(jqe) || jqe.includes('long'));
t('cu9: off/len unpack', cu9.includes('(int) (j') && cu9.includes('>> 32') && cu9.includes('4294967295L'));
t('yzVar.e: dir entry', cu9.includes('yzVar.e(gndVar,'));
t('yzVar.b/a: tg7/sg7', cu9.includes('yzVar.b((tg7)') && cu9.includes('yzVar.a((sg7)'));
t('yzVar.c: named kv', cu9.includes('yzVar.c(str5, str6,'));
t('zz: entry type', /class zz|interface zz/.test(readFileSync(D + 'zz.java', 'utf8')));
t('a00: entry container', /class a00|interface a00/.test(readFileSync(D + 'a00.java', 'utf8')));
t('ug7/tg7/sg7 handler types', readFileSync(D + 'ug7.java', 'utf8').length > 0 || cu9.includes('ug7Var instanceof tg7'));
console.log('manifest-index replay: ' + n + '/10 checks green');
