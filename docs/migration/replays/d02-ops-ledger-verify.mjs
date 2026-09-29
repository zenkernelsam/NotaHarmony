// Phase 989 — nce ops-ledger verify + z5c.i file CRC32 + uw7 materializer
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const nce = readFileSync(`${ROOT}/nce.java`, 'utf8');
const z5c = readFileSync(`${ROOT}/z5c.java`, 'utf8');
const uw7 = readFileSync(`${ROOT}/uw7.java`, 'utf8');
const o76 = readFileSync(`${ROOT}/o76.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// nce verify block — five checks
ok(/fileD\.exists\(\)[\s\S]{0,200}fileD\.length\(\) == j/.test(nce), 'nce: ops exists + size==pae.l');
ok(/new o76\("offsets file not found"\)/.test(nce), 'nce: offsets missing -> o76');
ok(/fileC\.length\(\) == \(\(long\) i5\) \* 4/.test(nce), 'nce: offsets len == count*4');
ok(/int i6 = z5c\.i\(fileD\);\s*int i7 = paeVarS0\.p;\s*if \(i6 == i7\)/.test(nce), 'nce: ops CRC32 == pae.p');
ok(/crc33\.update\(bArr3, 0, i12\)/.test(nce), 'nce: offsets raw CRC32 accumulate');
ok(/negative offset at index/.test(nce), 'nce: negative-offset check');
ok(/offset out of bounds at index/.test(nce), 'nce: bounds check');
ok(/first offset must be 0, got:/.test(nce), 'nce: first-offset==0 check');
ok(/non-monotonic offset at index/.test(nce), 'nce: monotonic check');
ok(/ops file size mismatch:/.test(nce), 'nce: size-mismatch message (l417)');

// z5c.i — file CRC32
ok(/public static int i\(File file\)/.test(z5c), 'z5c.i signature');
ok(/new CRC32\(\)[\s\S]{0,80}new byte\[65536\]/.test(z5c) && /crc32\.update\(bArr, 0, i2\)/.test(z5c) && /\(int\) crc32\.getValue\(\)/.test(z5c), 'z5c.i: 64K-chunk CRC32');
ok(/return 0;/.test(z5c), 'z5c.i: missing/empty -> 0');

// uw7 — ops+offsets materializer
ok(/if \(i == 0\)[\s\S]{0,30}return hw3\.I/.test(uw7), 'uw7: zero ops -> empty');
ok(/fileC\.length\(\) < i \* 4[\s\S]{0,80}Offsets file too short/.test(uw7), 'uw7: offsets too short');
ok(/randomAccessFile\.seek\(\(\(\(long\) i\) - 1\) \* 4\)[\s\S]{0,120}Ops file too short/.test(uw7), 'uw7: last-offset vs ops.length guard');
ok(/uq9Var\.d\(map\.position\(\) \+ map\.getInt\(map\.position\(\)\), map\)/.test(uw7), 'uw7: per-offset LE root read into uq9');

// o76 error wrapper
ok(/class o76|public.*o76\(/.test(o76), 'o76 error type exists');

console.log(`\nops-ledger-verify replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
