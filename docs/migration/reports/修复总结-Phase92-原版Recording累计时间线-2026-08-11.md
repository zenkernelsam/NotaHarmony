# Phase 92 修复总结：原版 Recording 累计时间线

## 原版证据

- 原版 `hkb` 对每条可播放录音计算有效时长：无 segment 时使用录音 `end-start`，有 segment 时只使用第一段
  `end-start`。
- `vna.c(index)` 累加当前索引之前的全部有效时长；`uw7.B(totalTime)` 选择最后一个“前缀时长不大于目标”的
  索引，再以 `目标-前缀` 作为该录音的局部 seek。目标恰好位于边界时会进入下一条录音。
- `ni9` case 12 计算总时长；case 13 先生成 `[0,d1,d1+d2,...,total]`，再去掉首尾，证明边界列表只包含录音间
  的内部累计时间。

## 已完成修复

- 新增 `OriginalRecordingTimeline`：只纳入本地 READY 录音，按原列表顺序生成 entry、累计起止、内部边界和总时长；
  MISSING/PENDING/FAILED 不再虚构可 seek 时长。
- uint64 绝对时间戳采用十进制逐位相减，避免先转 `number` 后在 `2^53` 以上丢失精度；超过播放器安全范围的异常
  entry 被局部隔离，不拖垮整份录音列表。
- 累计 seek 严格复刻原版边界语义：边界点进入下一录音，超过 total 时定位到最后录音末尾；跨录音时加载目标资产
  并在 prepared 后 seek 到局部偏移，原来处于播放态时继续 autoplay。
- 当前录音 completed 后自动加载并播放下一条可播放录音；最后一条保持 completed，可由原有按钮从总时间线起点重播。
- `RecordingPanel` 的 slider、elapsed 和 total 改为累计时间，不再错误显示单个 AVPlayer 文件时长。

## 边修边审新发现

- Phase 91 的可见返回按钮复制了保存/flush 逻辑，却绕过 `leaveEditor()`，播放器只能依赖 `aboutToDisappear()` 的异步
  兜底释放。现在可见返回和硬件返回统一走 `leaveEditor()`，先 flush，再 release AVPlayer/FD，最后路由返回。
- prepared 后的初始 seek 可能同步抛错；现由 controller 捕获并发布 FAILED snapshot，不允许异常逃出媒体事件回调。

## 验证

- 专项 replay：`recordingTimeline=first-segment-boundaries-global-seek-auto-advance`。
- 全量桌面 replay：`TOTAL=78 FAILED=0`。
- 执行 `hvigor clean` 后，`note@ohosTest` 与 `note@default` assembleHap 均为 `BUILD SUCCESSFUL`；仅有项目既有 deprecated/
  exception-handling warning。
- 未启动模拟器或真机。本阶段不虚报播放速度、录音采集、删除/重命名 outbound、波形、audio-ink、codec、音频焦点或
  设备声音输出闭环。
