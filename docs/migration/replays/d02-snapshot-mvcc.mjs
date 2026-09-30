// Phase 1254 — Compose snapshot MVCC internals
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const tjd = R('tjd.java');
t('tjd global rjd snapshot', tjd.includes('static rjd d'));
t('tjd e snapshot counter', tjd.includes('static long e'));
t('tjd c lock + h/i observers', tjd.includes('static final Object c') && tjd.includes('static List h'));
const osd = R('osd.java');
t('osd StateObjectImpl yc0 head', osd.includes('yc0 I'));
const zjd = R('zjd.java');
t('zjd extends psd versioned', zjd.includes('extends psd') && zjd.includes('long j, Object obj'));
const p6a = R('p6a.java');
t('p6a extends osd yjd', p6a.includes('extends osd implements Parcelable, yjd'));
t('p6a akd mutation policy', p6a.includes('akd J'));
t('p6a zjd K record', p6a.includes('zjd K'));
t('p6a e() 3-way merge', p6a.includes('psd e(psd psdVar, psd psdVar2, psd psdVar3)'));
t('p6a Parcelable', p6a.includes('Parcelable'));
console.log('snapshot-mvcc replay: ' + n + '/10 checks green');
