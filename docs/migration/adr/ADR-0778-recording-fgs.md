# ADR-0778 — 录音前台服务合约归档

- 状态：已接受（核心语义经连续任务对齐，细节登记）
- 证据：`docs/migration/evidence/phase-834-recording-fgs.md`
- 回放：`docs/migration/replays/d02-recording-fgs.mjs`（15/15）

## 原版合约

FGS id 2001；`process_token` 陈旧守卫 + `zt5` 会话单飞 +
限时 WakeLock + `ServiceStartNotAllowed` 降级 + LOW 常驻
通知 + `onBind`=null + START_NOT_STICKY。

## 决定

1. 核心语义（后台存活+用户可见提示）由 Harmony
   `startBackgroundRunning(AUDIO_RECORDING)` 承担——已对齐。
2. `process_token` 陈旧守卫、会话计数状态机、限时 wakelock
   为 Android 启动模型细节——登记不移植（Harmony 单 ability
   实例模型下陈旧 start 场景不存在）。
3. 通知渠道/图标/ONGOING 由系统横幅替代（ADR-0764 已登记）。

## 后果

录音服务面闭合：manifest（829 fst=microphone）+ 渠道（820）+
 本相位代码合约三层证据链完整。
