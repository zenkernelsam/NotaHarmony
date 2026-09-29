// Phase 991 — pae SyncedOpMetadata entity: 17 fields <-> 17 cols
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const pae = readFileSync(`${ROOT}/pae.java`, 'utf8');
const wp1 = readFileSync(`${ROOT}/wp1.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// 17-field ctor in column order
ok(/public pae\(ttf ttfVar, ttf ttfVar2, short s, ttf ttfVar3, long j, ttf ttfVar4, long j2, xgb xgbVar, String str, qo5 qo5Var, int i, long j3, int i2, short s2, Set set, int i3, int i4\)/.test(pae), 'pae: 17-arg ctor (ttf,ttf,short,ttf,long,ttf,long,xgb,String,qo5,int,long,int,short,Set,int,int)');

// field types
ok(/public final ttf a;[\s\S]{0,60}public final ttf b;[\s\S]{0,60}public final short c;/.test(pae), 'pae: a/b id+legacyId, c editorSiteId');
ok(/public final xgb h;/.test(pae) && /public final qo5 j;/.test(pae), 'pae: h=maxServerTime xgb, j=titleOpId qo5');
ok(/public final int k;[\s\S]{0,40}public final long l;/.test(pae), 'pae: k=opCount, l=opFileSize');
ok(/public final short n;[\s\S]{0,40}public final Set o;[\s\S]{0,40}public final int p;[\s\S]{0,40}public final int q;/.test(pae), 'pae: n=schemaVer, o=fingerprints, p/q=checksums');

// INSERT column order match
ok(/SyncedOpMetadata` \(`id`,`legacyId`,`editorSiteId`,`editorId`,`createdAt`,`creatorId`,`updatedAt`,`maxServerTime`,`title`,`titleOpId`,`opCount`,`opFileSize`,`maxTimestamp`,`schemaVersion`,`fingerprintFileLengths`,`opsChecksum`,`offsetsChecksum`\)/.test(wp1), 'wp1: 17-col INSERT order');

// copy() bitmask
ok(/\(i5 & 16384\) != 0 \? paeVar\.o/.test(pae) && /\(32768 & i5\) != 0 \? paeVar\.p/.test(pae) && /\(i5 & 65536\) != 0 \? paeVar\.q/.test(pae), 'pae.g: copy() bitmask o/p/q');
ok(/USER_VERIFY_ALL\) != 0 \? paeVar\.k/.test(pae) && /\(i5 & 2048\) != 0 \? paeVar\.l/.test(pae), 'pae.g: copy() bitmask k/l');

// ye9 interface
ok(/implements ye9/.test(pae) && /public final long a\(\) \{\s*return this\.e;/.test(pae), 'pae implements ye9: a()=createdAt');

console.log(`\nsynced-op-metadata-entity replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
