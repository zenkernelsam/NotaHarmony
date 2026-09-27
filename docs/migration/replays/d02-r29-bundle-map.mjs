// Phase 906 — r29 NoteBundle accessor 全图 + Harmony 对照回归
// 证据：docs/migration/evidence/phase-906-r29-bundle-map.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const ETS = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const r29 = rd('r29.java');

// ---- r29 accessor→c(N) ----
ok(r29.match(/utf o\(\)[\s\S]{0,120}c\(4\)/), 'r29.o -> c(4) noteId');
ok(r29.match(/utf n\(\)[\s\S]{0,120}c\(6\)/), 'r29.n -> c(6) legacyNoteId');
ok(r29.match(/short l\(\)[\s\S]{0,120}c\(8\)/), 'r29.l -> c(8) editorSite');
ok(r29.match(/String m\(\)[\s\S]{0,120}c\(10\)/), 'r29.m -> c(10) editorUserId');
ok(r29.match(/long j\(\)[\s\S]{0,120}c\(12\)/), 'r29.j -> c(12) createdAt');
ok(r29.match(/String k\(\)[\s\S]{0,120}c\(14\)/), 'r29.k -> c(14) creatorUserId');
ok(r29.match(/uq9 r\(uq9 uq9Var, int i\)[\s\S]{0,140}c\(16\)/), 'r29.r -> c(16) ops');
ok(r29.match(/short q\(\)[\s\S]{0,120}c\(18\)/), 'r29.q -> c(18) schemaVersion');
ok(r29.includes('extends cee implements ka4'), 'r29 cee+ka4');

// ---- Harmony 对照 ----
const hb = readFileSync(join(ETS, 'data/OriginalNoteBundlePageIdentity.ets'), 'utf8');
ok(hb.includes('readInlineBytes(0, 16)'), 'Harmony noteId field0 16B');
ok(hb.includes('readUint16(2, 0)'), 'Harmony editorSite field2');
ok(hb.includes('validateByteVector(3') && hb.includes('validateByteVector(5'),
  'Harmony editorUserId/creatorUserId fields 3/5');
ok(hb.includes('readTableVector(6'), 'Harmony ops vector field6');
ok(hb.includes('readUint16(7, 0)'), 'Harmony schemaVersion field7');
ok(hb.includes('unknown payload type') || hb.includes('payloadType < 1'),
  'Harmony strict payloadType gate (fail-closed)');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
