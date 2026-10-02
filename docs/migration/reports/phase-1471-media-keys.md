# Phase 1471 报告：音频回放媒体键（q5d.k.h/i/z 通道）

## 原版行为（1.4.2 证据）

键盘兜底链尾部 `f2.java:265-340`（`!rsi` 非文本编辑门内）：

- **Ctrl+Shift+DPAD_RIGHT** → `q5d.k.h()` = `min(累计位+10000, 总时长)`
  → `xke.w(d)` 累计位→录音索引+局部 ms 跨录音 seek。
- **Ctrl+Shift+DPAD_LEFT** → `q5d.k.i()` = `max(累计位−10000, 0)` → 同上。
- **纯 SPACE**（`!q&&!r&&!s`，UP）→ `q5d.k.z()` = PLAYING→`C()` 暂停、
  否则 `D()` 播放当前（录音列表空 → log+no-op）。
- 三支均 UP 动作、DOWN 亦消费；seek 支不查 Alt，SPACE 支全无修饰。
- `e6d`={PLAYING,PAUSED,STOPPED}；`q5d.p`=累计播放位、`q5d.q`=总时长。

## Harmony 缺口

录制回放设施齐备（`seekRecordingTimeline`/`toggleRecording`/
`playbackSnapshot`/`recordingTimeline`），但键盘无通路。

## 实现

- `OriginalKeyboardChords`：`ORIGIN_KEYCODE_SPACE=2050`、
  `ORIGIN_RECORDING_SEEK_STEP_MS=10000`。
- `NoteCanvasView` 新增 `onKeyRecordingSeekBy`/`onKeyRecordingPlayPause`
  回调 prop；`onCanvasKeyEvent` `!textEditing` 块尾部增两支。
- `NotePage`：seek→`clamp(pos+delta,0,total)`→`seekRecordingTimeline`
  （`xke.w` 等价）；toggle→当前或首条可见录音→`toggleRecording`
  （`z()` PLAYING↔非PLAYING 同核）。

## 验证

- 新 fixture `d02-original-media-keys.mjs`：20 项（键码/步长 pin、
  prop 声明、修饰键与 UP 门控、链序、NotePage 接线、可执行
  钳制/状态机模型）。
- `note@default` 构建通过；全量基线与 `note@ohosTest` 收尾验证。

## 遗留差异

- `D()` 内 `q5d.g==1→w()`/`==4→y()` 辅助分流未逐支复刻——
  `toggleRecording` 主路径覆盖；首播默认 player 近似为首条可见录音。
- `sgn.R` 协程活性门由 `total<=0` 防御等价。
