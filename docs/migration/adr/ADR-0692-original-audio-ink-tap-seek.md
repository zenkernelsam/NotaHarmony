# ADR-0692：原版 audio-ink tap-to-seek（h3 case28）移植

- 状态：Accepted
- 日期：2026-09-25
- 证据：`docs/migration/evidence/original-audio-ink-tap-seek-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-audio-ink-tap-seek.mjs`

## 背景

原版播放录音时点按画布，若命中 audio-linked ink（`bf0` 元素），
`h3` case28 会经 `vv7.S(bf0.c(), vv7.N(x09))` 把笔触的绝对
audio epoch 折回累计播放位并 seek —— 即"点字回听"交互。
`androidAudioInkSync` 打包默认 `true`，原生 1.0.3 无条件生效。

Harmony 此前仅移植了反向（播放驱动笔触动画，ADR-0069 体系），
缺 tap-to-seek 方向。`audioStartTime` 持久化、生效段表、
跨录音时间线与 `seekRecordingTimeline` 均已就位，本阶段补齐链路。

## 决定

1. `OriginalAudioLinkedInkPlayback.resolveOriginalAudioInkSeekTarget`：
   `vv7.S` 逐段累计语义（段时长钳位 ≥0、命中段返回累计+偏移、
   段外/反向段/空表 → null），按 `OriginalAudioSeekRecording[]`
   逐录音折回 `{recordingId, localPositionMs}` —— 本地播放位天然
   隔离多录音 epoch 基差。
2. `NoteCanvasView`：新增 `playbackIsPlaying` prop（h3 的
   `hoa.b==joa.I` 播放门）与 `audioSeekRecordings` prop +
   `onAudioInkSeekTap` 回调；`trySeekAudioLinkedInkAt` 复用
   `topmostPageElementIdAt`（`fu1.e` 两程命中同径）并要求命中元素
   为带 `audioStartTime` 的 STROKE（bf0 等价）。分发位点在 DEFAULT
   工具 tap 路径 tape 揭示/复选框/选区菜单之后、选区分发之前；
   命中即 `isDrawing=true` 消费点按。
3. `NotePage`：`audioSeekRecordings` 与 `audioPlaybackSegments`
   同源重建（`visiblePlaybackRecordings` ≈ `vv7.N` 未删除过滤）；
   `playbackIsPlaying` 接 `snapshot.state==PLAYING`；回调先做
   photoImport/pageStructure 租约门，再 `timelinePositionForRecording`
   → `seekRecordingTimeline`（与 RecordingPanel seek 同链，自动
   跨录音 load+resume），timeline 外 recordingId 防御丢弃。

## 影响

- 变更：`OriginalAudioLinkedInkPlayback.ets`（+resolver）、
  `NoteCanvasView.ets`（+2 props/1 callback/分发拦截）、
  `NotePage.ets`（+1 state/重建扩展/回调接线）。
- 行为：播放中点按音频联动笔触跳到书写时刻；其余点按路径不变。

## 记录在案的偏差

- 触发时点：原版在 tap 手势确认时 seek；Harmony 在 DEFAULT 工具
  Down 分发即 seek（与既有 applyTapSelect Down 提交约定一致）。
  Down 转拖拽的差为可接受等价偏差。
- 覆盖工具：仅 DEFAULT 工具路径；书写/橡皮/选区工具的点按继续走
  原绘制路径。原版 h3 位于全局点按拦截层，其跨工具生效范围静态
  不可完全判定，按"不改变绘制工具行为"保守移植。
- 非 READY 录音：Harmony 段表含未就绪录音段但回调按 timeline
  entry 防御丢弃（timeline 仅 READY）；原版 vv7.N 仅剔除删除标记，
  非加载录音的 seek 后续由播放器兜底 —— 两侧均不产生越界 seek。
