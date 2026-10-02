# ADR-1406: 音频回放媒体键（f2 → q5d.k.h/i/z 通道）

- **状态**: 已接受
- **日期**: 2026-08-10
- **阶段**: Phase 1471
- **关联**: evidence/phase-1471-media-keys.md
  （`f2:265-340`/`xke.h,i,z,w`/`e6d`/`q5d.p,q` 解码）

## 背景

原版键盘兜底链尾部实现音频回放媒体控制：Ctrl+Shift+DPAD_LEFT/RIGHT
对累计时间轴 seek ∓10s；纯 SPACE（无修饰键）UP 切换播放/暂停。
`q5d.k` = `xke` 包装 `q5d` 录制控制器；`q5d.p`=累计播放位、
`q5d.q`=总时长、`e6d`=PLAYING/PAUSED/STOPPED。Harmony 已有完整
回放设施（`seekRecordingTimeline`/`toggleRecording`/`playbackSnapshot`）
但无键盘通路。

## 决策

- `OriginalKeyboardChords` 新增 `ORIGIN_KEYCODE_SPACE=2050`、
  `ORIGIN_RECORDING_SEEK_STEP_MS=10000`。
- `NoteCanvasView` 增 `onKeyRecordingSeekBy(deltaMs)` 与
  `onKeyRecordingPlayPause()` 回调 prop，`onCanvasKeyEvent`
  `!textEditing` 块尾部分发：Ctrl+Shift+←/→（UP）→ seekBy(∓10000)；
  纯 SPACE（UP）→ playPause()；双向消费。
- `NotePage` 接线：seek = `clamp(pos+delta, 0, total)` →
  `seekRecordingTimeline`（`xke.w(d)` 累计位→单曲定位等价）；
  toggle = 当前 `playbackSnapshot.recordingId` ?? 首条可见录音 →
  `toggleRecording`。

## 等价性与边界

- 录制会话活性门（`sgn.R`/`q7d!=null`/空表 log）：Harmony 由
  `total<=0` 防御与 `seekRecordingTimeline` 空表回退等价。
- `D()` 的 `q5d.g` 分流支（intValue 1→w()、4→y()）未逐支复刻——
  `toggleRecording` load+resume 覆盖主路径，登记为残留差异。
- `!rsi` 门等价 `!textEditing`；修饰键门与原版逐位一致
  （seek 支不查 alt、SPACE 支全无修饰）。

## 验证

- `d02-original-media-keys.mjs` 20 项检查全绿（含钳制/状态机可执行模型）。
- 键盘族 fixture 无回归；`note@default`、`note@ohosTest` 构建通过。
