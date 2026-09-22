// Phase 559 — original recording presence indicator.
// Original evidence: rej.a renders a top-centered "Recording in progress"
// badge while the jub presence model is non-null (capture active, incl.
// paused); presence_recording_by_user ("%1$s is recording") is the
// collaboration variant. Harmony has no collaboration, so only the plain
// presence_recording string is ported.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const page = readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8');
const baseJson = JSON.parse(readFileSync('note/src/main/resources/base/element/string.json', 'utf8'));
const zhJson = JSON.parse(readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8'));
const baseVal = n => baseJson.string.find(e => e.name === n)?.value;
const zhVal = n => zhJson.string.find(e => e.name === n)?.value;

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Strings ---
check(baseVal('presence_recording') === 'Recording in progress', 'presence_recording EN verbatim');
check(zhVal('presence_recording')?.length > 0, 'presence_recording zh');

// --- Indicator gated on active capture state (incl. paused) ---
check(page.includes('isOriginalRecordingCaptureActive(this.recordingSessionSnapshot.captureState)'),
  'indicator gated on capture-active predicate');
check(page.indexOf('isOriginalRecordingCaptureActive(this.recordingSessionSnapshot.captureState)') <
  page.indexOf("Button($r('app.string.recordings'))"), 'indicator precedes recordings button in nav row');

// --- Badge contents: text + accessibility ---
const indIdx = page.indexOf('isOriginalRecordingCaptureActive(this.recordingSessionSnapshot');
const indBlock = page.slice(indIdx, indIdx + 1200);
check(indBlock.includes("$r('app.string.presence_recording')"), 'badge shows presence_recording');
check(indBlock.includes('accessibilityText'), 'badge carries a11y label');

// --- Predicate semantics: covers STARTING..STOPPING incl. PAUSED ---
const ctrl = readFileSync('note/src/main/ets/core/adaptation/OriginalRecordingSessionController.ets', 'utf8');
check(ctrl.includes('OriginalRecordingCaptureState.RECORDING') &&
  ctrl.includes('OriginalRecordingCaptureState.PAUSED'), 'predicate covers RECORDING+PAUSED');

// --- No collaboration variant ported (registered) ---
check(!page.includes('presence_recording_by_user'), 'by_user variant not ported');

console.log(`TOTAL=${n}`);
