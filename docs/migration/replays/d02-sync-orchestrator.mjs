// Phase 999 — 同步编排器（nr1 deps/flows/mutex + wq1 + q93 + pzb/ozb）
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const nr1 = readFileSync(D + 'nr1.java', 'utf8');
const wq1 = readFileSync(D + 'wq1.java', 'utf8');
const q93 = readFileSync(D + 'q93.java', 'utf8');
const pzb = readFileSync(D + 'pzb.java', 'utf8');
const ozb = readFileSync(D + 'ozb.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// q93 enum
t('q93: CREATE', q93.includes('"CREATE"'));
t('q93: APPEND', q93.includes('"APPEND"'));
t('q93: BUNDLE_DOWNLOAD', q93.includes('"BUNDLE_DOWNLOAD"'));
t('q93: SYNC_DOWNLOAD', q93.includes('"SYNC_DOWNLOAD"'));
// pzb/ozb = Kotlin Result
t('pzb.a = exceptionOrNull', /if \(obj instanceof ozb\)[\s\S]{0,80}return \(\(ozb\) obj\)\.I/.test(pzb));
t('ozb = Throwable carrier', /class ozb implements Serializable[\s\S]{0,120}public final Throwable I/.test(ozb));
// wq1 provider
t('wq1: provider get() builds nr1 with 8 deps', /return new nr1\(oq1Var[\s\S]{0,200}nceVar[\s\S]{0,200}v2fVar\)/.test(wq1));
// nr1 ctor
const ctor = nr1.slice(nr1.indexOf('public nr1('), nr1.indexOf('public static final Object a('));
t('nr1 ctor: oq1+nce stored', ctor.includes('this.a = oq1Var') && ctor.includes('this.b = nceVar'));
t('nr1: Room invalidation Flow on ClientOp', ctor.includes('"ClientOp"'));
t('nr1: Flow on {ClientOp,DraftNote}', ctor.includes('{"ClientOp", "DraftNote"}'));
t('nr1: shareIn via cq.u0 + we2 scope', /cq\.u0\(xn4VarR, we2VarA, ordVar, 1\)/.test(ctor));
t('nr1: two Mutex via fm8.a()', ctor.includes('this.m = fm8.a()') && ctor.includes('this.o = fm8.a()'));
t('nr1: LinkedHashMap n + bsd.a(0)', ctor.includes('new LinkedHashMap()') && ctor.includes('bsd.a(0)'));
// nr1.a op persist
const a = nr1.slice(nr1.indexOf('public static final Object a('), nr1.indexOf('public final Object b('));
t('nr1.a: ops->zp1 entities', a.includes('new zp1(ttfVar, (uq9)'));
t('nr1.a: withTransaction insert', a.includes('l96.L0('));
// nr1.b WAL consume
const b = nr1.slice(nr1.indexOf('public final Object b('));
t('nr1.b: post-consume File.delete', b.includes('.delete();'));
console.log('sync-orchestrator replay: ' + n + '/16 checks green');
