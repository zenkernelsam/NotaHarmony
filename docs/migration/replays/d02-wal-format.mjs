// Phase 983 — WAL format: ky write + fr1 read + nr1 store + hr1 filter
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const ky = readFileSync(`${ROOT}/ky.java`, 'utf8');
const nr1 = readFileSync(`${ROOT}/nr1.java`, 'utf8');
const fr1 = readFileSync(`${ROOT}/fr1.java`, 'utf8');
const hr1 = readFileSync(`${ROOT}/hr1.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// ky case 1 — WAL writer
ok(/au1\.R0\(\(Collection\) obj3, 100000\)/.test(ky), 'ky: chunk ops by 100000');
ok(/sb\.append\(jIncrementAndGet\);\s*sb\.append\("-"\);\s*sb\.append\(i4\);\s*sb\.append\("\.wal"\)/.test(ky), 'ky: <id>-<ns>-<seq>-<i>.wal name');
ok(/file2\.getName\(\) \+ "\.tmp"/.test(ky), 'ky: .tmp staging file');
ok(/dataOutputStream\.write\(ttfVar\.a\(\)\)/.test(ky), 'ky: 16B noteId header');
ok(/dataOutputStream\.writeInt\(list\.size\(\)\)/.test(ky), 'ky: BE op count');
ok(/dataOutputStream\.writeInt\(bArrB\.length\);\s*dataOutputStream\.write\(bArrB\)/.test(ky), 'ky: BE len + op bytes');
ok(/ree\.b\(\(uq9\) it3\.next\(\)\)/.test(ky), 'ky: ree.b(uq9) payload');
ok(/fag\.m0\(file3, file2\)/.test(ky), 'ky: fag.m0 tmp->wal rename');
ok(/Failed to write client ops WAL batch/.test(ky), 'ky: LOCAL_PERSISTENCE write-fail log');

// nr1 — WAL store
ok(/public static final AtomicLong s/.test(nr1), 'nr1.s = WAL AtomicLong seq');
ok(/r = ijg\.r0\(30, dr3Var\)/.test(nr1), 'nr1.r = 30s commit deadline');
ok(/Client ops WAL commit took too long/.test(nr1), 'nr1: slow-commit warning');
ok(/new String\[\]\{"ClientOp", "DraftNote"\}/.test(nr1), 'nr1: Room invalidation on ClientOp/DraftNote');
ok(/return xj2\.T\(t13\.K, new fr1\(0, null, file\), gr1Var\)/.test(nr1), 'nr1.h -> fr1(0) WAL read dispatch');

// fr1 case 0 — WAL reader
ok(/byte\[\] bArr = new byte\[16\];\s*dataInputStream\.readFully\(bArr\);\s*ttf ttfVarX = m18\.X\(bArr\)/.test(fr1), 'fr1: 16B noteId -> ttf');
ok(/int i2 = dataInputStream\.readInt\(\);\s*if \(i2 < 0 \|\| i2 >= 100001\)/.test(fr1), 'fr1: count guard <100001');
ok(/if \(1 > i4 \|\| i4 >= 10485761\)/.test(fr1), 'fr1: per-op guard <10MiB');
ok(/if \(j > 524288000\)/.test(fr1), 'fr1: total guard <=500MiB');
ok(/WAL op count out of range/.test(fr1) && /WAL op size out of range/.test(fr1) && /WAL total size exceeded/.test(fr1), 'fr1: three fail-closed messages');
ok(/byteBufferWrap\.order\(ByteOrder\.LITTLE_ENDIAN\);\s*uq9Var\.d\(byteBufferWrap\.position\(\) \+ byteBufferWrap\.getInt/.test(fr1), 'fr1: LE uoffset root read into uq9');
ok(/case 1:[\s\S]{0,200}file\.delete\(\)/.test(fr1), 'fr1 case1 = post-consume delete');

// hr1 — filename filters
ok(/svd\.f0\(str, "\.tmp", false\)/.test(hr1) && /svd\.f0\(str, "\.wal", false\)/.test(hr1), 'hr1: .tmp/.wal filters');
ok(/str\.startsWith\("aqs\."\)/.test(hr1) && /str\.startsWith\("event"\)/.test(hr1), 'hr1: aqs./event prefixes');

console.log(`\nwal-format replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
