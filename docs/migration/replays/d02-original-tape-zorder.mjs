// Phase 582 — original tape z-order rule (vnd.compareTo).
// Original evidence (decompiled_1.0.3/sources/defpackage/vnd.java:51-58):
//   compareTo first checks ly3.k() (isTape = InkTool==TAPE, s06:536 /
//   n5d:62-207). When exactly one side is tape, the tape element sorts LAST
//   (return other.k() ? -1 : 1) — tapes always render on top of all
//   non-tape elements regardless of zIndex; among themselves they keep the
//   normal (zIndex, id) ordering.
// Harmony markers: stroke renderSpec.tapePattern presence (StrokeTypes:
// "Presence identifies an original Tape stroke"); shape originalTool === 3
// (ElementTypes: "Pen=0, Pencil=1, Highlighter=2, Tape=3").
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const ORDER = 'note/src/main/ets/core/model/PageElementOrder.ets';
const doc = readFileSync(ORDER, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

const fn = doc.slice(doc.indexOf('export function materializePageElements'));
check(fn.length > 0, 'materializePageElements exists');

// Tape elements are moved after all non-tape elements (stable partition).
check(fn.includes('vnd.compareTo'), 'original comparator cited');
check(/renderSpec\.tapePattern !== undefined\s*&&\s*\n?\s*element\.data\.renderSpec\.tapePattern !== null/.test(fn)
  || /tapePattern !== undefined/.test(fn), 'stroke tape marker = tapePattern presence');
check(fn.includes('originalTool === 3'), 'shape tape marker = originalTool === 3 (TAPE)');
check(fn.includes('splice'), 'stable partition via splice');
// Partition runs before the transient top-stroke append (in-progress stroke
// still draws last, matching the original in-progress ink overlay).
check(fn.indexOf('originalTool === 3') < fn.indexOf('transientTopStroke !== null'),
  'tape partition precedes transient-top append');
// Tape detection covers BOTH strokes and shapes.
check(fn.indexOf('PageElementKind.STROKE') >= 0 &&
  fn.indexOf('PageElementKind.SHAPE', fn.indexOf('originalTool === 3') - 400) >= 0,
  'stroke + shape tape branches');

console.log(`D02_ORIGINAL_TAPE_ZORDER_OK TOTAL=${n} FAILED=0`);
