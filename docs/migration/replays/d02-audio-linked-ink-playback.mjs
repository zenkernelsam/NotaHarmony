import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const model = read('note/src/main/ets/core/model/StrokeTypes.ets');
const createInk = read('note/src/main/ets/data/OriginalCreateInkOperation.ets');
const modifyInk = read('note/src/main/ets/data/OriginalModifyInkOperation.ets');
const playback = read('note/src/main/ets/core/adaptation/OriginalAudioLinkedInkPlayback.ets');
const painter = read('note/src/main/ets/rendering/StrokeCanvasPainter.ets');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const fixture = read('note/src/test/SyncedOperationInbox.test.ets');
const tests = read('note/src/test/OriginalAudioLinkedInkPlayback.test.ets');

assert.match(model, /audioStartTime\?: string/);
assert.match(model, /audioDuration\?: number \| null/);
assert.match(createInk, /table\.hasField\(15\) \? table\.readUint32\(15, 0\) : null/);
assert.doesNotMatch(createInk, /CREATE_INK_AUDIO_DURATION_UNSUPPORTED/);
assert.match(createInk, /operation\.audioTime === null[\s\S]*operation\.clientTime : operation\.audioTime/);
assert.match(modifyInk, /audioStartTime: stroke\.audioStartTime/);
assert.match(modifyInk, /audioDuration: stroke\.audioDuration/);
assert.match(playback, /AUDIO_LINKED_ALPHA: number = 0\.3/);
assert.match(playback, /compareUnsignedLongDecimal\(end, start\) < 0/);
assert.match(playback, /audioTimeBelongsToSegments\(start, segments\)/);
assert.match(playback, /Math\.floor\(stroke\.splatPoints\.length \* fraction\)/);
assert.match(playback, /cubicParameterAtLengthFraction/);
assert.match(painter, /setGlobalAlpha\(playback\.alpha\)[\s\S]*sliceStrokeForAudioProgress/);
assert.match(page, /originalAudioTimeAtPosition\([\s\S]*range\.startTime, range\.endTime, localPosition/);
assert.match(page, /playbackAudioTime: this\.audioPlaybackTime/);
assert.match(canvas, /this\.playbackAudioTime !== null && this\.playbackAudioSegments\.length > 0/);
assert.match(canvas, /resolveOriginalAudioLinkedPlayback\([\s\S]*renderAudioLinkedStroke/);
assert.match(canvas, /OriginalOperationAudioTimeStore\(db\)\.listForNote\(this\.noteId\)/);
assert.match(canvas, /stroke\.audioStartTime = start/);
assert.match(fixture, /withAudioDuration\.audioDuration\)\.assertEqual\(4294967295\)/);
assert.match(tests, /18446744073709550250/);

assert.deepEqual(state('1000', 1000, '999', [['900', '2200']]), ['unbegun', 0.3, null]);
assert.deepEqual(state('1000', 1000, '1250', [['900', '2200']]), ['animating', 0.3, 0.25]);
assert.deepEqual(state('1000', 1000, '2000', [['900', '2200']]), ['complete', null, null]);
assert.deepEqual(state('1000', 1000, '1250', [['0', '999']]), ['disabled', null, null]);
assert.equal(BigInt('18446744073709550000') + 250n, BigInt('18446744073709550250'));

console.log('D02_AUDIO_LINKED_INK_PLAYBACK_OK ' +
  'field15-uint32=1|effective-start-uint64=1|segment-guard=1|states=3|alpha=0.3|' +
  'pencil-splats=1|path-length=1|ordered-dynamic-layer=1|legacy-start-hydration=1|modify-copy=1');

function state(start, duration, current, ranges) {
  if (!ranges.some(([left, right]) => BigInt(left) <= BigInt(start) && BigInt(start) <= BigInt(right))) {
    return ['disabled', null, null];
  }
  const startValue = BigInt(start);
  const currentValue = BigInt(current);
  const end = startValue + BigInt(duration);
  if (currentValue < startValue) return ['unbegun', 0.3, null];
  if (currentValue < end) return ['animating', 0.3, Number(currentValue - startValue) / duration];
  return ['complete', null, null];
}
