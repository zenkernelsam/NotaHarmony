# ADR-0540：原版录音播放 ±10 秒跳转

- 日期：2026-09-22
- 状态：已采纳

## 背景

原版音频播放器迷你控制条（`d32` case 6/7）提供快退/快进 10 秒按钮
（`zoa`/`woa` → `uw7.s()`/`r()`）：rewind = `max(pos−10000, 0)`，
forward = `min(pos+10000, duration)`。Harmony `RecordingPanel` 已有
播放/暂停、时间轴 slider、1x/1.5x/2x 倍速与删除/撤销，独缺 ±10s 跳转。

## 决策

在 RecordingPanel 时间轴行（位置/时长读数之间居中）加一对
`SkipButton`：点击把 `cumulativePositionMs ± 10000` clamp 到
`[0, cumulativeDurationMs]` 后走既有 `onSeek`（多录音聚合时间轴寻址，
`NotePage.seekRecordingTimeline` → `recordingController.seek`）。使能
复用 slider 的 `controlsEnabled && canSeek()`，点击守卫复用
`photoImportLeaseActive || loading`；a11y 文案取原版
"Rewind 10 seconds"/"Forward 10 seconds"。

## 后果

- 视觉形态：原版为专用图标，Harmony 用 `↺ 10s`/`10s ↻` 文本按钮，
  语义与 a11y 完全一致——登记为外观差异而非行为差异。
- 寻址落在聚合时间轴（`cumulativePositionMs`）而非单录音 position，
  与原版 `vna.o`/`p` 的聚合 ms 语义对应。
