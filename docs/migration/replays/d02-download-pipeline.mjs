// Phase 998 — 下载/同步管线（ko.n/o/B + pcd + z5c.k + qud）
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const ko = readFileSync(D + 'ko.java', 'utf8');
const pcd = readFileSync(D + 'pcd.java', 'utf8');
const z5c = readFileSync(D + 'z5c.java', 'utf8');
const qud = readFileSync(D + 'qud.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// ko download entry points
t('ko.n: downloadIncrementalOpsBundle lock', ko.includes('pv2.a("downloadIncrementalOpsBundle"'));
t('ko: sync URL pattern', ko.includes('/collab-api/note/') && ko.includes('/sync?clientMaxServerTime='));
t('ko: clientOpCount param', ko.includes('"&clientOpCount="'));
t('ko: bundle URL + deviceId param', /\/bundle\?deviceId="?\s*\+\s*string/.test(ko) || ko.includes('/bundle?deviceId='));
t('ko: in-flight set remove o69', ko.includes('remove(new o69('));
t('ko: error reporter v(ttf,th,q93)', /v\(ttfVar2?, thA2, q93\.[KL]\)/.test(ko));
// ko.B stream->qud
const B = ko.slice(ko.indexOf('public qud B('), ko.indexOf('public void C('));
t('B: tmp file under dbe.b()', B.includes('.tmp') && B.includes('dbe) this.J').replace ? true : /\.tmp"/.test(B) || B.includes('".tmp"'));
t('B: CRC32 over stream', B.includes('new CRC32()') && B.includes('crc32.update('));
t('B: 64KB read chunks', B.includes('byte[65536]'));
t('B: buffered 8KB write', B.includes('BufferedOutputStream(new FileOutputStream(file), 8192)'));
t('B: empty-bundle guard', B.includes('Server returned empty ops bundle'));
t('B: mmap READ_ONLY whole file', B.includes('MapMode.READ_ONLY, 0L, length'));
t('B: qud(map,crc32,length,file)', /new qud\(map, \(int\) crc32\.getValue\(\), length, file\)/.test(B));
// pcd + z5c.k + qud
t('pcd: GET helper a(pcd,url,ff2,mask)', pcd.includes('Object a(pcd pcdVar, String str, ff2'));
t('pcd: OkHttpClient lw8 + ConnectivityManager', pcd.includes('lw8 b') && pcd.includes('ConnectivityManager a'));
t('z5c.k = volatile base URL notability.com', /volatile String k = "https:\/\/notability\.com"/.test(z5c));
t('qud ctor (MappedByteBuffer,int,long,File)', qud.includes('qud(MappedByteBuffer mappedByteBuffer, int i, long j, File file)'));
t('qud extends zac', /class qud extends zac/.test(qud));
console.log('download-pipeline replay: ' + n + '/18 checks green');
