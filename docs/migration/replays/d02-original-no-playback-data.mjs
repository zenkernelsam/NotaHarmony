// Phase 570 — original "No playback data available" empty-timeline surface.
// Original evidence: faj.java renders
// feature_note_toolbox__no_playback_data_available ("No playback data
// available") when the playback timeline state is the empty variant
// (lpaVar2 == jpa.a); the data-present variant (kpa) renders the player
// controls instead.
// Harmony landing: RecordingPanel's timeline block renders the message text
// instead of the slider/timestamps when a recording is selected but has no
// playable data (cumulativeDurationMs <= 0, e.g. missing/failed asset).
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
check(baseVal('no_playback_data_available') === 'No playback data available',
  'EN verbatim');
check(zhVal('no_playback_data_available')?.length > 0, 'zh present');

// --- Panel structure ---
const timelineIdx = panel.indexOf('shouldShowRecordingTimeline(this.snapshot.recordingId)');
const emptyIdx = panel.indexOf('this.cumulativeDurationMs <= 0');
const msgIdx = panel.indexOf("$r('app.string.no_playback_data_available')");
const sliderIdx = panel.indexOf('Slider({ value: this.cumulativePositionMs');
check(timelineIdx >= 0 && emptyIdx > timelineIdx && msgIdx > emptyIdx,
  'empty branch inside timeline block');
check(sliderIdx > msgIdx, 'slider in the else branch');
// timestamps + skip buttons only render in the data-present branch
const posIdx = panel.indexOf('formatRecordingTime(this.cumulativePositionMs)');
const skipIdx = panel.indexOf('this.SkipButton(-ORIGINAL_RECORDING_SKIP_MS,');
check(posIdx > sliderIdx && skipIdx > sliderIdx,
  'time row and skip pair gated to data-present branch');
// message styling + centering
const msgRegion = panel.slice(msgIdx, msgIdx + 400);
check(msgRegion.includes('textAlign(TextAlign.Center)'), 'message centred');
check(msgRegion.includes('textSecondary'), 'message uses secondary text color');

// --- Playback semantics unchanged ---
check(panel.includes('this.cumulativeDurationMs > 0'), 'canSeek still requires duration');
check(panel.includes('Math.max(0, Math.min(this.cumulativeDurationMs,'),
  'skip clamp intact');
check(panel.includes('max: Math.max(1, this.cumulativeDurationMs)'),
  'slider max unchanged');

console.log(`D02_ORIGINAL_NO_PLAYBACK_DATA_REPLAY_OK TOTAL=${n} FAILED=0`);
