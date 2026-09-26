# ADR-0719 — 原版 1.4.2 后台 Worker 清单登记

日期：2026-09-29
状态：已登记（版本差清单；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-775-original-background-workers.md`
Replay：`docs/migration/replays/d02-original-background-workers.mjs`
上游：ADR-0708

## 背景

1.4.2 相对 1.0.3 新增 8 个 WorkManager Worker：五个属已登记簇
（画廊 outbox / 模板同步×2 / 贴纸×2），三个为新簇——
`BackgroundMaintenanceWorker`（domain/maintenance）、
`DemoResetWorker`（app/demo）、`UnresolvableWorker`
（core/workmanager）。`HandwritingPackDownloadWorker` 两版均有。

## 决策

| Worker | 处置 |
|---|---|
| BackgroundMaintenanceWorker | 本地语义登记：`ForegroundReturned` 取消异常使后台清扫向前台让位——可借鉴，列入待审 |
| DemoResetWorker | 零售演示重置——Harmony 无此场景，fail-closed |
| UnresolvableWorker | WorkManager 孤儿任务安全桩——架构注记，Harmony WorkScheduler 无同构问题 |

## 后果

- Replay 钉住 8 新增清单与三 Worker 特征断言。
- T-042 输入补齐后台任务面 diff。
