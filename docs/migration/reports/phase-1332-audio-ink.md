# Phase 1332 报告 — 音频关联笔迹回放

## 完成内容

- `OriginalAudioLinkedInkPlayback`：笔触携带
  `audioStartTime`/`audioDuration`（u64-decimal），
  `resolveOriginalAudioInkSeekTarget` 按播放时刻 seek
  时段笔迹（段归属+u64 比较），对照原版 `h3`/`vv7` —
  — Notability 标志性 audio-linked ink 回放保真；
  `OriginalOperationAudioTimeStore`+`PlaybackController`
  +`InternalAudioBackend` 配套。

## 产出

- evidence `phase-1332-audio-ink.md`
- fixture `d02-audio-ink.mjs`（10/10）
- ADR-1275
