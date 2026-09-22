// Phase 569 — original ±10s playback skip buttons in the recordings panel.
// Original evidence:
//  - d32 case 6/7 render icon buttons feature_note_toolbox__10secsback/
//    10secsforward_outline with a11y labels cd_rewind_10_seconds /
//    cd_forward_10_seconds ("Rewind 10 seconds" / "Forward 10 seconds").
//  - yna invokes zoa.a (Rewind) / woa.a (FastForward); npa.i dispatches to
//    uw7.s()/r().
//  - uw7.s: rewind = max(position - 10000, 0) → B(seek);
//    uw7.r: forward = min(position + 10000, duration) → B(seek).
// Harmony landing: RecordingPanel gains a SkipButton pair centred between the
// timeline position/duration readouts; clicks clamp
// cumulativePositionMs ± 10000 into [0, cumulativeDurationMs] and call onSeek,
// sharing the slider's controlsEnabled && canSeek() enablement and the
// photoImportLeaseActive/loading guard.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const panel = readFileSync('note/src/main/ets/ui/editor/RecordingPanel.ets', 'utf8');
const baseJson = JSON.parse(readFileSync('note/src/main/resources/base/element/string.json', 'utf8'));
const zhJson = JSON.parse(readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8'));
const baseVal = n => baseJson.string.find(e => e.name === n)?.value;
const zhVal = n => zhJson.string.find(e => e.name === n)?.value;

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Strings ---
check(baseVal('recording_rewind_10_seconds') === 'Rewind 10 seconds', 'rewind EN verbatim');
check(baseVal('recording_forward_10_seconds') === 'Forward 10 seconds', 'forward EN verbatim');
check(zhVal('recording_rewind_10_seconds')?.length > 0, 'rewind zh');
check(zhVal('recording_forward_10_seconds')?.length > 0, 'forward zh');

// --- Skip constant (uw7 ±10000ms) ---
check(panel.includes('ORIGINAL_RECORDING_SKIP_MS: number = 10000'), '10s skip constant');

// --- Buttons wired with original labels ---
check(panel.includes("$r('app.string.recording_rewind_10_seconds')"), 'rewind a11y label');
check(panel.includes("$r('app.string.recording_forward_10_seconds')"), 'forward a11y label');
check(panel.includes('this.SkipButton(-ORIGINAL_RECORDING_SKIP_MS,'), 'rewind = -skip');
check(panel.includes('this.SkipButton(ORIGINAL_RECORDING_SKIP_MS,'), 'forward = +skip');

// --- Placement: inside the timeline block between the time readouts ---
const timeRow = panel.indexOf('formatRecordingTime(this.cumulativePositionMs)');
const durRow = panel.indexOf('formatRecordingTime(this.cumulativeDurationMs)');
const rewindIdx = panel.indexOf('this.SkipButton(-ORIGINAL_RECORDING_SKIP_MS,');
const fwdIdx = panel.indexOf('this.SkipButton(ORIGINAL_RECORDING_SKIP_MS,');
check(timeRow >= 0 && rewindIdx > timeRow && fwdIdx > rewindIdx && durRow > fwdIdx,
  'skip pair centred between position/duration readouts');
check(panel.indexOf('shouldShowRecordingTimeline(this.snapshot.recordingId)') < timeRow,
  'inside the timeline block');

// --- SkipButton builder semantics ---
const builder = panel.slice(panel.indexOf('private SkipButton('),
  panel.indexOf('private SpeedButton('));
check(builder.includes('.accessibilityText(a11y)'), 'a11y label applied');
check(builder.includes('this.controlsEnabled && this.canSeek()'),
  'same enablement as slider');
check(builder.includes('this.photoImportLeaseActive || this.loading'),
  'lease/loading guard');
// uw7.s/r clamp semantics: max(0, min(dur, pos+delta))
check(builder.includes('Math.max(0, Math.min(this.cumulativeDurationMs,'),
  'clamp to [0, duration]');
check(builder.includes('this.cumulativePositionMs + deltaMs'), 'pos + delta');
check(builder.includes('this.onSeek(target)'), 'routes through onSeek');

console.log(`D02_ORIGINAL_RECORDING_SKIP_10S_REPLAY_OK TOTAL=${n} FAILED=0`);
