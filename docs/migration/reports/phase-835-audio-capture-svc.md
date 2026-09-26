# Phase 835 — 媒体内录服务代码语义

## 范围

`AudioCaptureService.java`（390 行）方法体审计——与 834 的
麦克风录音 FGS 构成音频双服务对。

## 原版发现

### 服务合约

- FGS id=**123**；channel `AudioCapture channel`
  （importance=3 DEFAULT，高于录音渠道的 LOW）；
- `onStartCommand` action-hash 分发：
  `"AudioCaptureService:Start"` + `Extra:ResultData` 传
  MediaProjection 授权 → `getMediaProjection(-1)`；
- `M` busy + 空 intent → NOT_STICKY；双异常降级。

### 采集管线（精确参数）

`AudioPlaybackCaptureConfiguration`(USAGE_MEDIA) → AudioRecord：
**PCM16 / 44100Hz / mono(channelMask=16) / 1024 缓冲** →
`filesDir/AudioCaptures/Recording-dd-MM-yyyy-hh-mm-ss.pcm`。

**语义定位**：系统播放内录（录"设备在放的"），与麦克风
录音服务（录"用户在说的"）互补。

## Harmony 侧

整条链 fail-closed：Harmony 无 MediaProjection/回放采集 API
（fst 面已 829 登记）。参数面固化备查。

## 验证

- 新 Replay `d02-audio-capture-svc.mjs`：**17/17**（FGS id/
  渠道/action 分发/投影授权/异常降级/采集参数×5/输出路径/
  bind=null）。
- ADR-0779。**应用级 3 service 代码语义全部闭合。**
