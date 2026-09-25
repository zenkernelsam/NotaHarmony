# Phase 736 报告：NbApplication 初始化链收口

- 日期：2026-09-25
- 性质：收口登记（无代码改动）
- ADR：ADR-0684
- 证据：`original-nbapplication-init-jadx-2026-09-25.md`
- Replay：`d02-original-nbapplication-init.mjs`

## 背景

继 MainActivity 属性（Phase 731）与方法（Phase 733）审计后，本阶段
关闭 Application 级启动面：`NbApplication.onCreate`（159-226 行）
逐项对源分类。原版进程入口文件至此全部关闭（NbApplication +
MainActivity + 清单组件 + 清单属性）。

## 分类结果

| 桶 | 初始化项 | 处置 |
| --- | --- | --- |
| 进程生命周期总线 | `wya`（ProcessLifecycleOwner）+ 8 个 DI 管理器订阅 | 消费者全为后端管线；Harmony 保留 onForeground/onBackground 钩子占位，结构性差异登记 |
| WorkManager 工位 | `v98`/`mx7` WorkerFactory + `rp8` 执行器池 ×4 | `ExportSweepWorker` 已由启动清扫承担（Phase 735）；`NoteAssetDownloadWorker` 后端边界；调度器本身平台边界 |
| 诊断件 | `StrictMode.LAX`、`ProcessFreezeDetector` 守护线程、`cj(pid)` "App Launch" 事件 | 开发诊断/遥测边界 |
| 内部管线 | `zb8`/`tl`/`j3e`/`y79`/`l3e`/`ch4`/`vv7`/`trb`/`lc4`/`fcb` 等静态装配 | DI 图内部接线，无独立可移植语义 |

## 关键判定

- `wya` 确认为 ProcessLifecycleOwner：`cf7` 生命周期注册表 +
  Activity start/stop 计数 + Handler 延迟派发；`ya0.s(wya.N)`
  即订阅进程级前后台事件。
- `cj` 确认为 "App Launch" 分析事件（PID 负载）。
- `ExportSweepWorker`→`r64`/`g64` 与 Phase 735 的清扫移植对齐。
- 16 个混淆 DI 管理器的消费面均属已登记边界，未发现未被覆盖的
  用户可话语义。

## 验证

- 专项 Replay：26 项断言全绿。
- 无代码改动；全量套件 + 双 HAP 按协议复验。
