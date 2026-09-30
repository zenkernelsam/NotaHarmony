# Phase 1332 证据 — 音频关联笔迹回放

来源：`core/adaptation/{OriginalAudioLinkedInkPlayback,
OriginalRecordingPlaybackController,OriginalRecordingInternal
AudioBackend}.ets`+`data/OriginalOperationAudioTimeStore.ets`。

## `OriginalAudioLinkedInkPlayback`

```
stroke.audioStartTime / audioDuration —— u64-decimal 字符串
resolveOriginalAudioInkSeekTarget(audioStartTime):
  validateUnsignedLongDecimal
  audioTimeBelongsToSegments(segments)
  compareUnsignedLongDecimal(time, seg.start/end) —— 落入段
  → playbackStroke(stroke, pathPoints, cubicSegments)
// 原版 h3 case28 → vv7.S(bf0.c(), vv7.N(x09))：
//   笔触 audioStartTime 关联回放
```

→ 笔迹携带音频时间戳 —— 播放时刻 seek 出该时段
书写的笔画（audio-linked note playback），对照原版
`h3`/`vv7`/`bf0.c`/`x09`。

## 关联组件

- `OriginalOperationAudioTimeStore` —— op 音频时间存储。
- `OriginalRecordingPlaybackController` —— 回放控制。
- `OriginalRecordingInternalAudioBackend` —— 内部音频后端。

## Harmony 决策

音频关联笔迹 = u64-decimal 时间戳 seek + 段归属判断 —
— 对照原版 `h3`/`vv7` 回放语义。

## 产出

- fixture `d02-audio-ink.mjs`（10 断言）。
- ADR-1275；中文报告。
