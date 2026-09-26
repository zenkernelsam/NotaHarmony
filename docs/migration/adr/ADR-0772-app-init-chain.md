# ADR-0772 — Application onCreate 初始化链映射

- 状态：已接受（启动架构收敛，平台差异登记）
- 证据：`docs/migration/evidence/phase-828-app-init-chain.md`
- 回放：`docs/migration/replays/d02-app-init-chain.mjs`（17/17）

## 原版模型

`NbApplication.onCreate`（decompiled_1.4.2）：

1. **进程分层**：进程名含 `:`（子进程）→ 仅 Crashlytics +
   process 标记后立即 return；主进程走完整链。
2. 主进程：StrictMode LAX 双策略 → `ProcessFreezeDetector` 守护
   线程 → `MobileMeasurement.start` Trace → ~15 个 `o1l.r` 惰性
   子系统注册（网络缓冲按设备分 40/80MB 档）→ 协程启动 →
   两个 WorkManager 唯一周期任务（BackgroundMaintenanceWorker
   12h/4h-flex、StickerPackPrefetchWorker CONNECTED）→
   `a40(Process.myPid())` 崩溃上下文标记。

## 决定

1. **启动路径语义保留、形态收敛**：Harmony `NoteAbility.onCreate`
   仅做 4 个 ingress 入队 + `ThemeStore.init` + colorMode +
   主题恢复 + `loadContent`——原版重初始化下沉至首帧/页面层。
2. **平台差异登记**（无对应概念，不 fail-close 亦不实现）：
   - 多进程应用模型（Harmony 无）；
   - StrictMode LAX（Android 调试策略）；
   - ProcessFreezeDetector（Harmony 由 HiAppEvent 系统级
     ANR/watchdog 承担）；
   - PID 崩溃标记。
3. **周期任务**：两个 Worker 已在 Phase 823 登记 fail-closed，
   本 ADR 确认其调度点为 onCreate 尾段（非延迟触发）。

## 后果

- 原版"Application 即初始化总线"模式 → Harmony 收敛为
  "Ability 轻入口 + 页面层初始化"，启动语义等价。
- Replay 固化 17 项断言：进程分层、LAX、看门狗、Trace、
  ≥10 子系统注册、双周期任务参数、PID 标记、Harmony 四
  ingress + ThemeStore + onNewWant 重入。
