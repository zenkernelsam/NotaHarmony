// Phase 1001 — kq1 ClientOp DAO + nr1 查询面
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const kq1 = readFileSync(D + 'kq1.java', 'utf8');
const nr1 = readFileSync(D + 'nr1.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// kq1 DAO anatomy
t('kq1: RoomDatabase field x5c', kq1.includes('public final x5c a'));
t('kq1: q36 insert adapter', kq1.includes('public final q36 d'));
t('kq1: q36 = wp1+iq1 pair', /new q36\(new wp1\(this, i\), new iq1\(this, i\)\)/.test(kq1));
t('kq1: sh8 precompiled holder', kq1.includes('new sh8(22)'));
t('kq1: iq1 b adapter', kq1.includes('new iq1(this, 0)'));
t('kq1.c: per-note query coroutine', /static Serializable c\(kq1 kq1Var, ttf ttfVar, ff2/.test(kq1));
t('kq1.a: per-note op', /Object a\(ttf ttfVar, kr1 kr1Var\)/.test(kq1));
// nr1 accessors
t('nr1.d: lazy kq1', nr1.includes('return (kq1) this.i.getValue()'));
t('nr1.e: lazy NoteBundleMetadataDatabase', nr1.includes('(NoteBundleMetadataDatabase) this.h.getValue()'));
t('nr1.f: read tx -> Set', nr1.includes('l96.L0(dr1Var, kq1VarD.a, true, false') && nr1.includes('au1.X1('));
t('nr1.g: createFlow-style query', nr1.includes('l96.J0(') && nr1.includes('new jq1(kq1VarD, ttfVar'));
t('nr1: invalidation helper ys2.r', nr1.includes('ys2.r('));
console.log('clientop-dao replay: ' + n + '/12 checks green');
