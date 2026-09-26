# Phase 828 — Application onCreate 初始化链

## 范围

证据：`decompiled_1.4.2/sources/com/gingerlabs/notability/app/NbApplication.java`

## 原版发现

### 进程分层

`onCreate` 首段：进程名含 `:` → 子进程分支，仅做
`FirebaseCrashlytics` + `process` 维度标记后立即 return——
**子进程不跑主初始化**（vendor SDK 自声明的辅助进程）。

### 主进程序列（源码顺序）

1. `StrictMode.ThreadPolicy.LAX` + `VmPolicy.LAX` —— 显式关闭
   StrictMode（双策略）；
2. `ProcessFreezeDetector` 守护线程（CAS 单例启动）；
3. `MobileMeasurement.start` Trace 段 + 分析开关；
4. ~15 个 `o1l.r(...)` 惰性子系统注册（`b().X2.invoke()` =
   DI 组件 getter；`lme` 内网络缓冲按设备 40MB/80MB 分级）；
5. `dob`/`s93`/`j6c`/`nae` 协程启动；
6. **BackgroundMaintenanceWorker** 唯一周期任务：12h 周期 +
   4h flex + 300s 抖动；
7. **StickerPackPrefetchWorker** 唯一任务（CONNECTED 约束）；
8. `a40(Process.myPid())` —— 记录 PID 至崩溃上下文（末行）。

## Harmony 侧

`NoteAbility.onCreate`：4 个 ingress 入队（shared want /
launch action / deep link / open target）+ `ThemeStore.init()`
+ `setColorMode(NOT_SET)` + 主题恢复 + `loadContent(pages/Index)`。
无多进程模型、无 StrictMode/看门狗概念——重初始化下沉至
页面层，启动语义保留。

## 差异登记

| 原版 | Harmony | 处置 |
|------|---------|------|
| 子进程 minimal init | 无多进程应用模型 | 登记平台差 |
| StrictMode LAX | 无对应 | 登记 |
| ProcessFreezeDetector | HiAppEvent 系统级检测 | 登记 |
| 双周期 Worker | 无 workScheduler 等价 | Phase 823 已 fail-closed |
| PID 崩溃标记 | 无 | 登记 |

## 验证

- 新 Replay `d02-app-init-chain.mjs`：**17/17**（进程分层、
  LAX、看门狗线程名、Trace 段、≥10 子系统注册、40/80MB、
  12h/4h/300s 任务参数、PID 标记、Harmony 四 ingress +
  ThemeStore + onNewWant）。
- ADR-0772。
