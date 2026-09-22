// Phase 581 — original GIF ingress/render boundary.
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   qc.java (insert menu): "Add GIF" item rendered only when function4 is
//   non-null — a host-supplied picker callback, statically unresolvable.
//   oj3.java: gif is in the supported image set (oj3.a/b) shared by file
//   picker (ff5), drag-drop (sl), and pasteboard (yne) — no special-casing.
//   ly.java/jy.java: animation renders via AnimatedImageDrawable (dedicated
//   animated view), not the static-bitmap path.
// Harmony: ImageAssetLoader already fail-closes GIF to ANIMATED_UNSUPPORTED
// (no AnimatedImageDrawable equivalent in the canvas pipeline).
// Also pins the HANDOVER-COMMANDER version annotation fix: the audit's
// reference/defpackage baseline is the 1.0.1 obfuscation map.
import { readFileSync, existsSync } from 'node:fs';
import assert from 'node:assert';

const LOADER = 'note/src/main/ets/core/adaptation/ImageAssetLoader.ets';
const HO = 'docs/migration/HANDOVER-COMMANDER.md';
const EV = 'docs/migration/evidence/original-gif-ingress-decode-2026-09-28.md';

const loader = readFileSync(LOADER, 'utf8');
const ho = readFileSync(HO, 'utf8');
const ev = readFileSync(EV, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// GIF fail-closed leg
check(/image\/gif/.test(loader) && loader.includes('ANIMATED_UNSUPPORTED'),
  'GIF assets fail-closed to ANIMATED_UNSUPPORTED');
check(loader.includes('dedicated image view'),
  'fail-closed reason cites the dedicated animated view');

// Evidence doc exists and records the decode
check(existsSync(EV), 'evidence doc exists');
check(ev.includes('oj3') && ev.includes('AnimatedImageDrawable') &&
  ev.includes('add_gif'), 'evidence records oj3/AnimatedImageDrawable/add_gif');
check(ev.includes('function4'), 'records the function4 picker blind spot');

// HANDOVER-COMMANDER version annotation (register-mandated fix)
check(/1\.0\.1/.test(ho) && /reference\/defpackage/.test(ho),
  'HANDOVER-COMMANDER annotates reference/defpackage as 1.0.1');
check(ho.includes('1.0.3'), 'annotation contrasts with 1.0.3');

console.log(`D02_ORIGINAL_GIF_INGRESS_BOUNDARY_OK TOTAL=${n} FAILED=0`);
