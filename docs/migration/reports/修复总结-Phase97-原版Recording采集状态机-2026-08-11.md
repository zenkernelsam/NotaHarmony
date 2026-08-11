# Phase 97 修复总结：原版 Recording 采集状态机

## 原版证据

- `tr8/iu8` 证明 1.0.3 使用 Android audio source 6（`VOICE_RECOGNITION`）、MPEG-4、AAC、
  44,100 Hz、单声道和 96,000 bps；recorder 成功 start 后才记录 wall time 与 monotonic uptime。
- pause 时保存 monotonic 时刻，resume 时累计暂停区间；`wr8.e()` 从 fallback elapsed 中同时排除
  已完成与仍在进行的暂停区间。
- `ky` case 11 在 stop 后优先读取媒体 duration metadata，并以 `start + duration` 构造 end；读取失败
  回退 monotonic elapsed。prepare/start 失败时 `wr8.h()` release recorder 并删除临时输出。

## 已完成修复

- 新增 `OriginalRecordingCaptureController`，以 `AsyncMutex` 串行化 start/pause/resume/stop/abort/release，
  完整区分 idle、各过渡态、recording、paused、failed 与永久 released；非法或重复转换不会触碰后端。
- 注入 wall/uptime clock；严格在成功 start 后取起点，fallback 时排除 pause，stop 后优先采用经校验的
  媒体 metadata duration，并按原版使用 `start + duration` 而非停止时 wall clock。
- 新增 Harmony AVRecorder 后端。边修边审发现 Android source 6 不能简单等同普通 MIC，现改用语义对应的
  `AUDIO_SOURCE_TYPE_VOICE_RECOGNITION`；其余 profile 精确保持 AAC/MPEG-4、mono、44.1 kHz、96 kbps。
- 输出写入应用 tempDir 的独占临时文件；stop 后校验普通非空文件，通过 `AVMetadataExtractor` 读取时长，
  成功才转交路径。start/stop/error/abort/release 的失败路径均尽力注销监听、stop/release recorder、关闭 FD
  并删除未完成文件。
- 后端异步 error 会串行进入 FAILED 并清理。边修边审同时修复两个任意类型原样 rethrow 导致的 ArkTS
  生产编译错误，改为带 start/stop 上下文的明确 `Error`。
- manifest 增加 `ohos.permission.MICROPHONE` 与中英文用途说明；`NotePage` 只初始化并在所有退出路径 release
  controller。当前没有 Record UI、没有运行时权限请求，也不会启动 recorder，避免暴露不能持久化的半成品。
- 新增 ArkTS 测试并注册测试套件，覆盖原版 profile/source、pause duration、metadata 优先、uptime fallback、
  start failure cleanup、异步 recorder error 与 release 后禁止复用。

## 验证

- 专项 replay：`recordingCapture=original-aac-pause-duration-temp-cleanup`。
- 全量桌面 replay：`TOTAL=83 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均为
  `BUILD SUCCESSFUL`；仅有项目既有 warning。
- 未启动模拟器或真机，未执行设备 Hypium、麦克风、codec、音频焦点或文件系统体验验收。

## 剩余边界

本阶段只闭环采集与临时文件生命周期，不虚报已经能保存一条 Recording。Phase 98 应将完成文件原子移入
资产仓库、计算 AssetHash、精确编码并 apply CREATE_RECORDING、在同一事务写 operation log，并在任一步失败时
回滚数据库和文件。完成该闭环后才能加入运行时权限请求和 Record/pause/resume/stop UI。audio focus/interruption、
DEVICE_ONLY 内部音频、真实 codec/声音质量仍需后续能力判断与设备验收。Goal 保持 active。
