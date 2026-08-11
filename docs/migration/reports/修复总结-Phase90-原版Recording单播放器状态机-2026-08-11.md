# Phase 90 修复总结：原版 Recording 单播放器状态机

## 原版与平台边界

原版 `vna` 只持有一个 ExoPlayer，`xpa/pna` 把播放器回调汇入状态，`uw7` 负责播放、暂停、seek
和 completed 后从总时间线 0 重播。原版可一次设置多个 media item；Harmony 当前 AVPlayer API 没有
同等 playlist 合约，因此本阶段只关闭“单个录音的正确播放器生命周期”，跨录音时间线留给上层。

## 已完成修复

- 新增 `OriginalRecordingPlaybackController`，严格按 Harmony 状态约束执行
  idle→initialized→prepared→playing/paused/completed/error。
- `fdSrc` 设置后等待 initialized 回调再 prepare；prepared 才允许自动播放。time/duration/error/state
  回调统一发布不可变 snapshot。
- load/play/pause/release 用 `AsyncMutex` 串行化；每次 load 与最终 release 都推进 generation，迟到的
  create/prepare/play 与旧 player 回调不能污染新录音。
- 快速切换时先注销旧 handler 并 release 旧 AVPlayer，之后才关闭 Phase 89 的 FD lease。同步设置
  `fdSrc` 失败也走同一注销、release、close 顺序。
- completed 再播放会先 seek(0)，seek 仅在 SDK 允许的状态生效并限制到有效 duration；release 是
  terminal，释放后不能重新 load。

## 未虚报范围

本阶段尚未接 NotePage UI、录音列表、自动跨录音 advance、累计时间线、播放速度、波形、audio-ink
同步或采集。codec 与真实声音输出必须在设备上验收。

## 验证

- 专项 replay：`recordingPlayback=single-player-generation-release-before-fd-close`。
- 全量桌面 replay：`TOTAL=76 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均为
  `BUILD SUCCESSFUL`。仅有项目既有 deprecated/exception-handling warning。
