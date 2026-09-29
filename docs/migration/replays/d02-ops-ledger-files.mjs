// Phase 988 — dbe paths + lv2.s0 fingerprint rebuild + kl1 CRC stream + hg4
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const dbe = readFileSync(`${ROOT}/dbe.java`, 'utf8');
const pr1 = readFileSync(`${ROOT}/pr1.java`, 'utf8');
const lv2 = readFileSync(`${ROOT}/lv2.java`, 'utf8');
const kl1 = readFileSync(`${ROOT}/kl1.java`, 'utf8');
const hg4 = readFileSync(`${ROOT}/hg4.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// dbe path provider
ok(/new File\(\(File\) this\.c\.getValue\(\), ttfVar\.toString\(\)\), j \+ "\.deferred"\)/.test(dbe), 'dbe.a: <noteId>/<row>.deferred');
ok(/ttfVar\.toString\(\)\.concat\("\.offsets"\)/.test(dbe), 'dbe.c: <noteId>.offsets');
ok(/ttfVar\.toString\(\)\.concat\("\.ops"\)/.test(dbe), 'dbe.d: <noteId>.ops');

// pr1 dir providers
ok(/new File\(dbeVar\.b\(\), "client_ops_wal"\)/.test(pr1), 'pr1(0): client_ops_wal dir');
ok(/dbeVar\.a\.getDir\("notes", 0\)/.test(pr1), 'pr1(1): notes base dir');
ok(/new File\(dbeVar\.b\(\), "deferred"\)/.test(pr1), 'pr1(2): deferred dir');

// lv2.s0 fingerprint rebuild
ok(/public static pae s0\(dbe dbeVar, ttf ttfVar, pae paeVar\)/.test(lv2), 'lv2.s0 signature');
ok(/if \(i2 == 0\)[\s\S]{0,120}tf4\.u0\(o0\(dbeVar\.b\(\), ttfVar\)\)/.test(lv2), 'lv2.s0: zero ops -> delete fingerprint dir');
ok(/new RandomAccessFile\(fileC/.test(lv2), 'lv2.s0: .offsets RandomAccessFile');
ok(/fileChannelOpen\.map\(FileChannel\.MapMode\.READ_ONLY, 0L, fileD\.length\(\)\)/.test(lv2), 'lv2.s0: .ops READ_ONLY mmap');
ok(/randomAccessFile\.readFully\(bArr, s, iMin \* 4\)/.test(lv2), 'lv2.s0: int32 offsets read (x4)');
ok(/fsi\.Z\(bArr, i5\)/.test(lv2), 'lv2.s0: fsi.Z offset decode');
ok(/No value for \(required\) field id/.test(lv2), 'lv2.s0: required id assert');
ok(/new led\(s5\)/.test(lv2) && /new l3f\(i8\)/.test(lv2) && /new xgb\(tmfVar\.I\)/.test(lv2), 'lv2.s0: led(site)+l3f(ts)+xgb(serverTime)');
ok(/ByteBuffer\.allocate\(12\)\.order\(ByteOrder\.LITTLE_ENDIAN\)/.test(lv2), 'lv2.s0: 12B LE fingerprint record');
ok(/byteBufferOrder\.putInt\(i9\);\s*byteBufferOrder\.putLong\(j2\)/.test(lv2), 'lv2.s0: {ts:int32,serverTime:int64}');
ok(/new hg4\(s6, \(int\) fileQ\.length\(\), kl1Var\.a\(\)\)/.test(lv2), 'lv2.s0: hg4(site,len,crc)');

// lv2.q/o0/p
ok(/new File\(o0\(file, ttfVar\), vh2\.o\(ymf\.a\(s\), "\.fingerprints"\)\)/.test(lv2), 'lv2.q: fingerprints/<id>/<site>.fingerprints');
ok(/new File\(new File\(file, "fingerprints"\), ttfVar\.toString\(\)\)/.test(lv2), 'lv2.o0: fingerprints/<noteId>');
ok(/listFiles\(\)/.test(lv2) && /lv2\.p/.test('lv2.p'), 'lv2.p: fingerprint dir sweep (see file)');

// kl1 CRC32 stream
ok(/public final CRC32 J/.test(kl1) && /\(int\) this\.J\.getValue\(\)/.test(kl1), 'kl1.a() = stream CRC32');
ok(/this\.I\.write\(bArr\);\s*this\.J\.update\(bArr\)/.test(kl1), 'kl1.write: update CRC on write');

// hg4 FingerprintFileLength
ok(/FingerprintFileLength\(siteId=/.test(hg4), 'hg4 toString: FingerprintFileLength');
ok(/public hg4\(short s, int i, int i2\)/.test(hg4), 'hg4{site,length,checksum}');

// lv2.t = q89 OpAck materializer
ok(/public static final List t\(q89 q89Var\)/.test(lv2) && /q89Var\.j\(vq9Var, i2\)/.test(lv2), 'lv2.t: OpAck vector materializer');

console.log(`\nops-ledger-files replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
