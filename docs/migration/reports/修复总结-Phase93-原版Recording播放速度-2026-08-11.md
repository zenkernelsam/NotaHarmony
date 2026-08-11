# Phase 93 修复总结：原版 Recording 播放速度

## 原版与 SDK 证据

- 原版 `wna` 只有 1.0、1.5、2.0 三档；`n05.b` 把枚举完整渲染为分段控制，`npa` 在选择时更新状态并设置活动播放器。
- 原版 `uw7.G()` 每次开始播放前都会重新应用当前速度，因此速度属于播放器会话状态，不属于单个录音文件。
- 本机 Harmony SDK 明确 `AVPlayer.setSpeed(PlaybackSpeed)` 只允许 prepared/playing/paused/completed，并通过
  `speedDone` 回报生效模式；SDK 恰好提供原版三档对应枚举。

## 已完成修复

- `OriginalRecordingPlaybackController` 新增严格三值速度状态。idle/loading 时选择会保留到 prepared；prepared 后先设置速度，
  再执行 Phase 92 初始 seek 和 autoplay；活动播放器则立即切换。
- `setSpeed` 同步失败会回滚旧选择并发布 FAILED，不让 UI 虚报已接受速度。`speedDone` 与其他媒体 handler 一样受
  generation/player 防护，并在 release/switch 时注销。
- `RecordingPanel` 累计时间行新增紧凑 1x/1.5x/2x 分段按钮，选中态使用既有主题 accent；跨录音自动续播仍保留所选速度。

## 边修边审新发现

- 不能把每个 `speedDone` 与“当前期望速度”直接比较：快速点 1.5x 后再点 2x 时，合法的旧 1.5x 确认可能迟到。
  现允许三个原版模式的迟到确认，只拒绝原版范围外的意外模式，避免快速切档把播放器误判 FAILED。

## 验证

- 专项 replay：`recordingSpeed=original-three-modes-prepared-before-play-speedDone`。
- 全量桌面 replay：`TOTAL=79 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均为 `BUILD SUCCESSFUL`；仅有项目既有 warning。
- 未启动设备，不虚报 codec、实际声音速度/音高、音频焦点、输出路由、录音采集、waveform 或 audio-ink 验收。
