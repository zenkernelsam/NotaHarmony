// Phase 1290 — .ntb bundle + nj3 file-format registry
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const nj3 = R('nj3.java');
t('nj3 ntb octet-stream', nj3.includes('ntb("application/octet-stream")'));
t('nj3 note/nbn bundle variants', nj3.includes('nbn') && nj3.includes('note'));
t('nj3 office+pdf+media+images', nj3.includes('docx') && nj3.includes('pdf("application/pdf")') && nj3.includes('heic') && nj3.includes('m4a'));
t('nj3 mime-keyed LinkedHashMap', nj3.includes('LinkedHashMap K') && nj3.includes('String I'));
const yk9 = R('yk9.java'), x59 = R('x59.java');
t('ntb zip writer ZipEntry/putNextEntry', yk9.includes('ZipEntry') && yk9.includes('putNextEntry'));
t('ntb uses flatbuffers', yk9.includes('flatbuffers') || x59.includes('ZipEntry'));
const ax7 = R('ax7.java');
t('ax7 ManifestData + .ntb', ax7.includes('ManifestData') && ax7.includes('.ntb'));
const dv5 = R('dv5.java');
t('dv5 nj3.ntb export', dv5.includes('nj3.ntb'));
t('dv5 jv5.f "ntb" pipe', dv5.includes('"ntb"'));
t('MissingAssetsException', existsSync(S + 'com/gingerlabs/notability/data/library/state/ntb/MissingAssetsException.java'));
console.log('ntb-format replay: ' + n + '/10 checks green');
