// Phase 1199 — Compose snapshot MVCC internals (tjd global + zjd/psd records + yjd policy + osd)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const tjd = R('tjd.java');
t('tjd global snapshot class', tjd.includes('class tjd'));
t('tjd rjd current snapshot', tjd.includes('rjd'));
t('tjd long e counter', tjd.includes('long e'));
t('tjd Object c lock', tjd.includes('Object c'));
t('tjd zec/yc6 observers', tjd.includes('zec') && tjd.includes('yc6'));
const zjd = R('zjd.java');
t('zjd extends psd (state record)', zjd.includes('extends psd'));
t('zjd c(long)→psd versioned read', zjd.includes('psd c(long'));
t('zjd a(psd) merge record', zjd.includes('a(psd'));
t('osd implements nsd + yc0 field', R('osd.java').includes('implements nsd') && R('osd.java').includes('yc0'));
t('yjd extends gl8 (MutationPolicy)', R('yjd.java').includes('extends gl8'));
console.log('snapshot-mvcc replay: ' + n + '/10 checks green');
