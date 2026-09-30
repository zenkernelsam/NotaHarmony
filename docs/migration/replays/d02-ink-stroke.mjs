// Phase 1259 — ka8/i5g/t16 ink-stroke model
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ka8 = R('ka8.java');
t('ka8{Path,List,i5g,Path,Float}', ka8.includes('final Path a') && ka8.includes('final i5g c') && ka8.includes('final Float e'));
t('ka8 ctor 5 args', ka8.includes('ka8(Path path, List list, i5g i5gVar, Path path2, Float'));
const i5g = R('i5g.java');
t('i5g{color,size,t16,2xbool}', i5g.includes('final int a') && i5g.includes('final float b') && i5g.includes('final t16 c'));
t('i5g accessor a/b/c/d/e', i5g.includes('float a()') && i5g.includes('t16 c()'));
const t16 = R('t16.java');
t('t16 VARIABLE_WIDTH', t16.includes('VARIABLE_WIDTH'));
t('t16 FIXED_WIDTH/DASH/DOTS', t16.includes('FIXED_WIDTH') && t16.includes('DASH') && t16.includes('DOTS'));
t('t16 byte I ordinal', t16.includes('final byte I'));
const nfe = R('nfe.java');
t('nfe Path() factory', nfe.includes('new Path()'));
t('nfe ty4 Function0', nfe.includes('extends ty4 implements Function0'));
t('ka8 imports Path', ka8.includes('import android.graphics.Path'));
console.log('ink-stroke replay: ' + n + '/10 checks green');
