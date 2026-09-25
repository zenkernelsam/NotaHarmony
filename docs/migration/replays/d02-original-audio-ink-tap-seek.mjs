import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const playback = read('note/src/main/ets/core/adaptation/OriginalAudioLinkedInkPlayback.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');

// 原版证据（h3 case28 + vv7.S/vv7.N，decompiled_1.0.3）：
// 播放中点按 → fu1.e 命中 → 命中元素须为 bf0（audio-linked ink，
// Harmony 等价 = audioStartTime 存在的 STROKE）→ vv7.S 把笔触
// 绝对 audio epoch 折回段内累计播放位 → seek。段外/非联动/未播放 →
// 落空走原分发。androidAudioInkSync 打包默认 true → 无条件生效。

// ---- 源码 pin：纯函数（vv7.S 逐段累计语义）----
assert.match(playback, /export interface OriginalAudioSeekRecording \{/);
assert.match(playback, /export interface OriginalAudioInkSeekTarget \{/);
assert.match(playback, /export function resolveOriginalAudioInkSeekTarget\(/);
assert.match(playback, /validateUnsignedLongDecimal\(audioStartTime\)/);
// 段时长钳位 >=0 + 段内命中 → 累计 + 偏移（vv7.S 的 d2 + max(0, j-d)）。
assert.match(playback,
  /compareUnsignedLongDecimal\(audioStartTime, segment\.startTime\) >= 0[\s\S]*compareUnsignedLongDecimal\(audioStartTime, segment\.endTime\) <= 0/);
assert.match(playback, /localPositionMs: accumulatedMs \+ \(offset >= 0 \? offset : 0\)/);
assert.match(playback, /accumulatedMs \+= duration/);

// ---- 源码 pin：画布门 + 命中链 ----
assert.match(canvas, /@Prop playbackIsPlaying: boolean = false/);
assert.match(canvas, /@Prop audioSeekRecordings: OriginalAudioSeekRecording\[\] = \[\]/);
assert.match(canvas, /onAudioInkSeekTap: \(target: OriginalAudioInkSeekTarget\) => void/);
// 命中链：topmostPageElementIdAt（fu1.e 同径）→ STROKE + audioStartTime（bf0 等价）。
assert.match(canvas, /this\.topmostPageElementIdAt\(canvasP\)/);
assert.match(canvas, /s\.audioStartTime !== undefined/);
assert.match(canvas,
  /resolveOriginalAudioInkSeekTarget\(\s*stroke\.audioStartTime, this\.audioSeekRecordings\)/);
// 播放门 + 消费语义（isDrawing 阻断后续分发）。
assert.match(canvas,
  /if \(this\.playbackIsPlaying && this\.trySeekAudioLinkedInkAt\(canvasP\)\) \{\s*this\.isDrawing = true;\s*return;/);

// ---- 源码 pin：NotePage 落地 ----
assert.match(page, /@State audioSeekRecordings: OriginalAudioSeekRecording\[\] = \[\]/);
assert.match(page, /seekList\.push\(\{ recordingId: recording\.id, segments: ranges \}\)/);
assert.match(page,
  /this\.playbackSnapshot\.state === OriginalRecordingPlaybackState\.PLAYING/);
assert.match(page, /photoImportLeaseActive \|\| this\.pageStructureLeaseActive/);
assert.match(page,
  /timelinePositionForRecording\(\s*this\.recordingTimeline, target\.recordingId, target\.localPositionMs\)/);
assert.match(page, /this\.seekRecordingTimeline\(/);

// ---- 运行时模型：resolveOriginalAudioInkSeekTarget ----
// recordings: [{recordingId, segments:[[start,end]...]}]（生效段，epoch 字符串）。
function resolve(audioStartTime, recordings) {
  const t = BigInt(audioStartTime);
  for (const rec of recordings) {
    let acc = 0;
    for (const [s, e] of rec.segments) {
      const d = BigInt(e) - BigInt(s);
      const dur = d > 0n ? Number(d) : 0;
      if (BigInt(s) <= t && t <= BigInt(e)) {
        const off = Number(t - BigInt(s));
        return { recordingId: rec.recordingId, localPositionMs: acc + (off >= 0 ? off : 0) };
      }
      acc += dur;
    }
  }
  return null;
}
const R = (recordingId, segments) => ({ recordingId, segments });

// 单段内命中：epoch 1000..5000，t=3000 → 本地 2000。
assert.deepEqual(resolve('3000', [R('a', [['1000', '5000']])]),
  { recordingId: 'a', localPositionMs: 2000 });
// 段端点两端含（vv7.S 无符号闭区间）。
assert.deepEqual(resolve('1000', [R('a', [['1000', '5000']])]),
  { recordingId: 'a', localPositionMs: 0 });
assert.deepEqual(resolve('5000', [R('a', [['1000', '5000']])]),
  { recordingId: 'a', localPositionMs: 4000 });
// 段间空隙（暂停/裁剪间隙）：t=5500 落在 5000..6000 间隙 → null。
assert.equal(resolve('5500', [R('a', [['1000', '5000'], ['6000', '9000']])]), null);
// 间隙后第二段命中：之前段时长累计 4000 + 偏移 500 = 4500。
assert.deepEqual(resolve('6500', [R('a', [['1000', '5000'], ['6000', '9000']])]),
  { recordingId: 'a', localPositionMs: 4500 });
// 反向段（end<start）按原版钳位时长 0、不可命中。
assert.equal(resolve('7000', [R('a', [['9000', '6000']])]), null);
// 跨录音：t 属第二录音 → recordingId + 该录音本地播放位。
assert.deepEqual(resolve('20500',
  [R('a', [['1000', '5000']]), R('b', [['20000', '26000']])]),
  { recordingId: 'b', localPositionMs: 500 });
// 早于首段/晚于末段/空表 → null（h3 tap_null 落空）。
assert.equal(resolve('500', [R('a', [['1000', '5000']])]), null);
assert.equal(resolve('9999', [R('a', [['1000', '5000']])]), null);
assert.equal(resolve('3000', []), null);
// u64 边界：epoch 大数值安全差分。
assert.deepEqual(resolve('18446744073709550250',
  [R('a', [['18446744073709550000', '18446744073709551000']])]),
  { recordingId: 'a', localPositionMs: 250 });

console.log('D02_ORIGINAL_AUDIO_INK_TAP_SEEK_OK ' +
  'pins=17|single-segment=3|gap-null=1|accumulate=1|reverse-null=1|' +
  'cross-recording=1|outside-null=3|u64-boundary=1');
