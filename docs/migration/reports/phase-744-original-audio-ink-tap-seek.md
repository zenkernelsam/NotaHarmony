# Phase 744 — 原版 audio-ink tap-to-seek（h3 case28）移植（ADR-0692）

日期：2026-09-25

## 结论

补齐原版"点字回听"交互的最后一段：播放录音时点按画布上的
音频联动笔触（原版 `bf0` 元素），把播放进度跳到该笔触书写时刻。
Harmony 此前已具备全部数据基础（`audio_time` 持久化、
`audioStartTime` 字段、生效段表、跨录音时间线、`seekRecordingTimeline`、
z 序命中），缺的只是 `h3` 点按→`vv7.S` 折回→seek 的接线。
本阶段按原版语义完成移植，登记两处等价偏差。

## 原版证据（h3 case28 + vv7）

- `h3.java` case28：`androidAudioInkSync` 旗标（打包默认 true）→
  播放态 `joa.I` 门 → 笔记/录音非空 → `fu1.e` 页坐标命中 →
  命中须为 `bf0` → `vv7.S(bf0.c(), vv7.N(x09))` 折回 →
  `playback.relative_ms` seek 并消费点按；任一关卡落空返回 null
  走原手势分发。
- `vv7.N`：非删除录音按起始序取逐段表扁平化；`vv7.S`：逐段
  时长钳位 ≥0 累计，时间戳落入 `[start,end]` 闭区间 →
  累计+段内偏移，全部落空 → null。
- 详见 `docs/migration/evidence/original-audio-ink-tap-seek-jadx-2026-09-25.md`。

## 变更

- `OriginalAudioLinkedInkPlayback.ets`：新增
  `OriginalAudioSeekRecording`/`OriginalAudioInkSeekTarget` 与
  `resolveOriginalAudioInkSeekTarget` —— `vv7.S` 逐段累计语义的
  逐录音版本，返回 `{recordingId, localPositionMs}`，无符号十进制
  全程校验。
- `NoteCanvasView.ets`：`playbackIsPlaying`/`audioSeekRecordings`
  props + `onAudioInkSeekTap` 回调 + `trySeekAudioLinkedInkAt`
  （`topmostPageElementIdAt` 命中 → STROKE + `audioStartTime` →
  resolver → 上抛并消费）。拦截位在 DEFAULT 工具 tap 路径的
  tape 揭示/复选框/选区菜单之后、选区分发之前。
- `NotePage.ets`：`audioSeekRecordings` 与既有
  `audioPlaybackSegments` 同源重建；`playbackIsPlaying` 接
  PLAYING 态；回调租约门 → `timelinePositionForRecording` →
  `seekRecordingTimeline`（跨录音自动 load+resume），timeline 外
  recordingId 防御丢弃。

## 验证

- 专项 Replay `d02-original-audio-ink-tap-seek.mjs`：29/29 绿
  （17 源码 pin + 12 运行时：单段/双端点/间隙 null/累计/反向段/
  跨录音/段外 null×3/u64 边界）。
- 全量 Desktop Replay：9071+29=9100 全绿（见下）。
- `note@ohosTest` / `note@default` 两 HAP clean 构建通过。

## 记录在案的偏差（ADR-0692）

- 触发时点：原版 tap 手势确认时 seek；Harmony DEFAULT 工具 Down
  分发即 seek（同 applyTapSelect 既有约定）。
- 覆盖范围：仅 DEFAULT 工具路径；绘制类工具点按不产生 seek
  （原版跨工具生效范围静态不可完全判定，保守移植）。
- 非 READY 录音段命中由回调 timeline 门防御丢弃，不产生越界 seek。

## 备注

Phase 743 报告将 AUDIO_INK_SYNC 归为"已登记独立契约"；本阶段
实际移植后该分类作废，归并为已移植项。
