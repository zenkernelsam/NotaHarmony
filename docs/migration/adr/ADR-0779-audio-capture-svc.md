# ADR-0779 — 媒体内录服务合约归档

- 状态：已接受（fail-closed 语义固化）
- 证据：`docs/migration/evidence/phase-835-audio-capture-svc.md`
- 回放：`docs/migration/replays/d02-audio-capture-svc.mjs`（17/17）

## 原版合约

`AudioCaptureService`：FGS id 123 + DEFAULT 重要性渠道；
`AudioCaptureService:Start` action + ResultData 传递投影授权；
`AudioPlaybackCaptureConfiguration`(USAGE_MEDIA) →
AudioRecord PCM16/44.1kHz/mono/1024 缓冲 →
`filesDir/AudioCaptures/Recording-<date>.pcm` 原始 PCM；
双异常降级 + NOT_STICKY。

## 决定

1. 整条系统音频内录链 fail-closed：Harmony 无 MediaProjection/
   回放采集等价 API（fst=mediaProjection 已在 ADR-0773 登记）。
2. 参数面固化备查：44.1kHz/单声道/16bit/PCM——若未来平台
   开放内录，按此规格对齐。
3. 与录音 FGS（834）明确区分：本服务录"设备在放的"，
   彼服务录"用户在说的"——两者互补不重叠。

## 后果

应用级 3 个 service 的代码语义全部闭合（FGS 合约×2 +
: hwr 进程服务 fail-closed）。
