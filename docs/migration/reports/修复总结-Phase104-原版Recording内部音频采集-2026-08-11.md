# Phase 104 修复总结：原版 Recording 内部音频采集

## 原版证据

- 原版 `bkb` 明确定义 `MIC / DEVICE_ONLY` 两种来源，对应 `Microphone / Internal Audio`，因此
  Internal Audio 不是不可达枚举或可以删除的残留代码。
- 原版 `xjb.i()` 在 `AudioManager.isMusicActive()` 为 false 时直接走 MIC；只有系统音乐活跃时才
  打开二选一音源界面。
- 原版 `vp8.a()` 返回 false，pause/resume 只记录“不支持”日志；Internal Audio 不能伪装成支持暂停。
- 原版 `AudioCaptureService` 使用 MediaProjection、`AudioPlaybackCaptureConfiguration` 和
  `addMatchingUsage(1)` 捕获系统播放，音频格式为 44.1 kHz、mono、PCM 16-bit，最终形成录音资产。

## 已完成修复

- 增加 `OriginalRecordingAudioSource`、双后端 source router 和后端 capability，MIC 与 Internal Audio
  复用既有 capture/session/persist 主链，但权限、audio focus 与 Pause 行为按来源分离。
- `NotePage` 先查询 `STREAM_USAGE_MUSIC`：无音乐直接开始 MIC；有音乐显示 Microphone/Internal Audio
  两个原版选项。选择 Internal Audio 时不请求麦克风权限、不抢 media focus，面板不显示 Pause。
- 新增 `libnota_recording.so` NAPI bridge，以 Harmony `OH_AVScreenCapture` 的 `OH_ALL_PLAYBACK`、
  AAC-LC、MPEG-4 audio、44.1 kHz、mono、96 kbps 写入受 ArkTS FD 生命周期保护的临时 M4A。
- native bridge 串行持有单个 capture，覆盖 start/stop/abort、privacy state/error callback、主动 stop
  回调抑制、外部 stop 判定与旧实例迟到 callback 隔离；新页面不能抢走仍活动 capture 的 callback。
- 系统用户停止、其他捕获抢占、通话和用户切换都进入 session stop/save，而不是 abort 丢弃资产。
  边修边审又修复 STARTED 后立即外部 stop 的窗口：`STARTING` 期间的中止会排在 in-flight start 后
  完成 stop、文件校验和持久化，不会留下“UI 仍在录音、native 已停止”的假状态。

## 验证

- 全部 Recording 专项 replay 通过；新增输出：
  `recordingInternalAudio=music-gated-source-native-m4a-no-mic-no-focus-no-pause-save-on-stop`。
- 新增/扩展 ArkTS 测试覆盖：DEVICE_ONLY 不请求 MIC 权限、不激活 focus、不允许 pause、系统中止保存，
  以及 native start 后立即中止仍保存。`note@ohosTest` 增量 assembleHap 为 `BUILD SUCCESSFUL`。
- 全量桌面 replay：`TOTAL=90 FAILED=0`。
- 执行 `hvigor clean` 后串行构建 `note@ohosTest` 与 `note@default`，均为
  `BUILD SUCCESSFUL`；只有项目既有 warning。

## 仍需设备验收

本阶段没有启动模拟器、虚拟机或真机，也没有执行设备 Hypium。Harmony 系统隐私授权弹窗的实际文案与
取消路径、音乐活跃检测、真实系统播放捕获、生成 M4A 的时长/可播放性、系统录屏指示、通话/用户切换/
其他捕获中止，以及不同应用是否允许 playback capture，均须在设备上验收。代码已保留失败与系统中止
收敛路径，但不把这些设备行为虚报为已验证。Goal 保持 active，继续边修边补审。
