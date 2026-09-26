# Phase 834 — 录音前台服务代码语义

## 范围

`RecordingForegroundService.java` 方法体审计（补 829 manifest
层 + 820 渠道层之外的可执行合约）。

## 原版发现

### 启动合约

- `startForeground(2001, ...)`：FGS id=2001；
- **`process_token` 守卫**：intent token 不匹配进程级 K →
  "stale start" 日志 + stopSelf，START_NOT_STICKY；
- **`zt5` 会话单飞**：AtomicReference 计数，并发启动拒绝；
- **限时 WakeLock**：`wg4.g(I)` 超时包裹获取；
- **`ServiceStartNotAllowed` 降级**：分级日志 + 条件 stopSelf。

### 通知/生命周期

- 懒建 `notability_recording` 渠道（importance=2 LOW）；
- app_mark 图标 + `flags|=2`+`p=true` **常驻不可划除**；
- `onBind`=null；`onDestroy` 释放 wakelock+协程作用域。

## Harmony 侧

`startBackgroundRunning(AUDIO_RECORDING, wantAgent)` 系统横幅
+ `stopBackgroundRunning` 退出——核心语义对齐；token 守卫/
计数/wakelock 细节为平台差登记（单 ability 模型下场景不存）。

## 验证

- 新 Replay `d02-recording-fgs.mjs`：**15/15**（token 守卫、
  id 2001、NOT_STICKY、会话计数、限时锁、降级路径、渠道
  LOW、常驻 flag、bind=null、destroy 释放、Harmony 三断言）。
- ADR-0778。**录音服务三层证据链（manifest/渠道/合约）闭合。**
