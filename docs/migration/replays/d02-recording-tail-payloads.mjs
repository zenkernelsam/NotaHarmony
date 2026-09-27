// Phase 873 — 录音/尾部 op payload（类型 1,2,5,6,27–31）登记回归
// 证据：docs/migration/evidence/phase-873-recording-tail-payloads.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- zq9 映射 ----
const zq9 = readFileSync(join(SRC, 'zq9.java'), 'utf8');
const map = [['l2d','SET_METADATA'],['ra0','ASSET_CLOUD_PERSISTED'],
             ['yn2','CREATE_RECORDING'],['ke8','MODIFY_RECORDING'],
             ['ee8','MODIFY_PDF_FIELD'],['mqf','UPDATE_CHECKBOX'],
             ['yda','PEER_INTERACTION'],['tl2','CREATE_COMMENT'],
             ['ud8','MODIFY_COMMENT']];
for (const [cls, name] of map) {
  ok(zq9.includes(`${cls}.class), haa.${name}`), `${name} -> ${cls}`);
}

// ---- 录音 ----
const yn2 = readFileSync(join(SRC, 'yn2.java'), 'utf8');
ok(/akb l\(\)[\s\S]{0,200}c\(4\)/.test(yn2), 'yn2 f0 = akb recording-id');
ok(/String k\(\)[\s\S]{0,200}c\(10\)/.test(yn2), 'yn2 f2 = String name');
ok(/ukb o\(ukb ukbVar, int i\)[\s\S]{0,200}c\(12\)/.test(yn2), 'yn2 f4 = ukb segment vector');
const ke8 = readFileSync(join(SRC, 'ke8.java'), 'utf8');
ok(/qo5 k\(\)[\s\S]{0,200}c\(4\)/.test(ke8), 'ke8 f0 = qo5 target');
ok(/String j\(\)[\s\S]{0,200}c\(6\)/.test(ke8), 'ke8 f1 = name setter');
ok(/ukb n\(ukb ukbVar, int i\)[\s\S]{0,200}c\(8\)/.test(ke8), 'ke8 f2 = ukb segment vector');
ok(/tmf m\(\)[\s\S]{0,200}c\(10\)/.test(ke8), 'ke8 f3 = tmf');

// ---- checkbox/pdf-field/comment/peer ----
const mqf = readFileSync(join(SRC, 'mqf.java'), 'utf8');
ok(/qo5 k\(\)[\s\S]{0,200}c\(4\)/.test(mqf), 'mqf f0 = qo5 block');
ok(/cxc j\(\)[\s\S]{0,200}c\(6\)/.test(mqf), 'mqf f1 = cxc checkbox pos');
ok(/boolean l\(\)[\s\S]{0,200}c\(8\)/.test(mqf), 'mqf f2 = checked boolean');
const ee8 = readFileSync(join(SRC, 'ee8.java'), 'utf8');
ok(/ua0 j\(\)[\s\S]{0,200}c\(4\)/.test(ee8), 'ee8 f0 = ua0 asset');
ok(/String k\(\)[\s\S]{0,200}c\(6\)/.test(ee8), 'ee8 f1 = fieldKey');
ok(/Boolean l\(\)[\s\S]{0,200}c\(12\)/.test(ee8), 'ee8 f4 = Boolean');
const tl2 = readFileSync(join(SRC, 'tl2.java'), 'utf8');
ok(/im j\(\)[\s\S]{0,200}c\(4\)/.test(tl2), 'tl2 f0 = im comment-id');
ok(/String k\(\)[\s\S]{0,200}c\(8\)/.test(tl2), 'tl2 f2 = String text');
const ud8 = readFileSync(join(SRC, 'ud8.java'), 'utf8');
ok(/qo5 k\(\)[\s\S]{0,200}c\(4\)/.test(ud8), 'ud8 f0 = qo5 comment target');
const yda = readFileSync(join(SRC, 'yda.java'), 'utf8');
ok(/qo5 o\(qo5 qo5Var, int i\)[\s\S]{0,200}c\(10\)/.test(yda), 'yda f3 = qo5 vector');
ok(/u76 n\(\)[\s\S]{0,200}c\(12\)/.test(yda), 'yda f4 = u76 peer payload');

// ---- SET_METADATA / ASSET ----
const l2d = readFileSync(join(SRC, 'l2d.java'), 'utf8');
ok((l2d.match(/z2d [a-z]\(\)/g) || []).length >= 2, 'l2d has z2d setters (title etc)');
ok(/m2d p\(\)[\s\S]{0,200}c\(6\)/.test(l2d), 'l2d f1 = m2d background setter');
ok(/dz0 k\(\)[\s\S]{0,200}c\(18\)/.test(l2d), 'l2d f7 = dz0 setter');
const ra0 = readFileSync(join(SRC, 'ra0.java'), 'utf8');
ok(/ua0 j\(\)[\s\S]{0,200}c\(4\)/.test(ra0), 'ra0 = single ua0 asset field');

// ---- Harmony 覆盖 ----
for (const f of ['OriginalCreateRecordingPayloadEncoder.ets', 'OriginalRecordingOperation.ets',
                 'OriginalSetMetadataPayloadEncoder.ets', 'OriginalModifyPdfFieldOperation.ets',
                 'OriginalLocalCheckboxMutation.ets', 'OriginalCommentOperation.ets',
                 'OriginalPeerInteractionOperation.ets', 'OriginalAssetMetadata.ets']) {
  ok(readFileSync(`note/src/main/ets/data/${f}`, 'utf8').length > 300, `${f} exists`);
}
const ro = readFileSync('note/src/main/ets/data/OriginalRecordingOperation.ets', 'utf8');
ok(ro.includes('name_winner_timestamp') && ro.includes('segments_winner_timestamp') &&
   ro.includes('z_index_winner_timestamp'), 'recording 3 winner registers (ke8 setters)');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
