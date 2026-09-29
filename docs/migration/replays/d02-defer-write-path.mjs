// Phase 985 — nce.g defer gate + nce.u atomic commit + crb-17 writer + w63.a + ebe
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const nce = readFileSync(`${ROOT}/nce.java`, 'utf8');
const crb = readFileSync(`${ROOT}/crb.java`, 'utf8');
const w63 = readFileSync(`${ROOT}/w63.java`, 'utf8');
const ebe = readFileSync(`${ROOT}/ebe.java`, 'utf8');
const fsi = readFileSync(`${ROOT}/fsi.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// nce.g — schema gate
ok(/if \(ba6\.w\(zaeVar\.b\(\) & 65535, 65535 & rgc\.a\) > 0\)/.test(nce), 'nce.g: u16 schema compare gate');
ok(/Cannot defer empty blob for note/.test(nce), 'nce.g: empty blob refuse');
ok(/fsi\.r\(byteBufferC, new byte\[Math\.min\(\(int\) jLimit, 65536\)\]\)/.test(nce), 'nce.g: CRC32 w/ 64K scratch');
ok(/new crb\(byteBufferC, 17\)/.test(nce), 'nce.g: crb-17 writer lambda');

// nce.u — atomic defer commit
ok(/x63 x63VarA = zaeVar\.a\(\);\s*if \(x63VarA == null\)[\s\S]{0,140}Should be impossible/.test(nce), 'nce.u: null format -> IllegalState');
ok(/pv2\.c\(this\.d, hceVar, gceVar2\)/.test(nce), 'nce.u: Room tx via pv2.c');
ok(/new hce\(paeVar, this, ttfVar, zaeVar, x63VarA, j, i, ix4Var, null\)/.test(nce), 'nce.u: hce tx lambda (fmt+size+crc+writer)');
ok(/"Deferred ops for note"/.test(nce) && /"new\.schema"/.test(nce) && /"current\.schema"/.test(nce), 'nce.u: defer log fields');

// crb case 17 — exclusive blob writer
ok(/case 17:[\s\S]{0,400}fsi\.z\(file\)/.test(crb), 'crb-17: fsi.z parent ensure');
ok(/FileChannel\.open\(file\.toPath\(\), StandardOpenOption\.WRITE, StandardOpenOption\.CREATE_NEW\)/.test(crb), 'crb-17: WRITE+CREATE_NEW');
ok(/byteBufferDuplicate\.position\(0\);\s*while \(byteBufferDuplicate\.hasRemaining\(\)\)[\s\S]{0,40}fileChannelOpen\.write\(byteBufferDuplicate\)/.test(crb), 'crb-17: full-buffer write loop');

// crb case 18 — qud download move
ok(/case 18:[\s\S]{0,400}fag\.m0\(qudVar\.M, file2\);\s*qudVar\.N = true/.test(crb), 'crb-18: atomic move + N flag');
ok(/StreamedDownload already moved/.test(crb), 'crb-18: double-move guard');

// w63.a — enum-name converter
ok(/str\.equals\("NOTE_BUNDLE"\)[\s\S]{0,80}return x63\.I/.test(w63), 'w63.a: NOTE_BUNDLE->I');
ok(/str\.equals\("OPS_BUNDLE"\)[\s\S]{0,80}return x63\.J/.test(w63), 'w63.a: OPS_BUNDLE->J');
ok(/str\.equals\("RECEIVE_OPS_EVENT"\)[\s\S]{0,80}return x63\.K/.test(w63), 'w63.a: RECEIVE_OPS_EVENT->K');
ok(/Can't convert value to enum, unknown value/.test(w63), 'w63.a: unknown -> throw');

// ebe = SUCCESS/CORRUPT_NEEDS_REDOWNLOAD
ok(/new ebe\("SUCCESS", 0\)/.test(ebe) && /new ebe\("CORRUPT_NEEDS_REDOWNLOAD", 1\)/.test(ebe), 'ebe: SUCCESS/CORRUPT_NEEDS_REDOWNLOAD');

// fsi.z = parent mkdirs
ok(/public static final void z\(File file\)[\s\S]{0,200}fag\.F\(parentFile\)/.test(fsi), 'fsi.z: parent mkdirs');

console.log(`\ndefer-write-path replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
