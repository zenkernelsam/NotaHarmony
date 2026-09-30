# ADR-1275：音频关联笔迹回放

## 状态

已接受（Phase 1332）。

## 决策

音频关联笔迹 = u64-decimal 时间戳 seek + 段归属判断
—— 对照原版 `h3`/`vv7` 回放语义。

## 理由

`OriginalAudioLinkedInkPlayback`：笔触携带
`audioStartTime`/`audioDuration`（u64-decimal），
`resolveOriginalAudioInkSeekTarget` 按播放时刻 seek
出该时段书写的笔画（`audioTimeBelongsToSegments`+
`compareUnsignedLongDecimal` 段归属），对照原版
`h3 case28`/`vv7.S`/`bf0.c`/`x09`。

## 后果

Notability 标志性 audio-linked ink 回放语义保真 ——
播放音频可联动显示对应时段笔迹。
