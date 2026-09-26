# Phase 775 — 原版 1.4.2 后台 Worker 清单登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-775-original-background-workers.md`
ADR：`ADR-0719-original-background-workers.md`
Replay：`d02-original-background-workers.mjs`（5/5）

## 本阶段做了什么

对两版本 `com/gingerlabs` 全量 `*Worker.java` 做文件名 diff：
1.4.2 新增 8 个、删除 0 个。其中五个已随功能簇登记
（画廊/模板×2/贴纸×2），三个新簇本阶段取证：

- `BackgroundMaintenanceWorker` + `ForegroundReturned`
  CancellationException——后台维护任务在应用回前台时主动取消
  （让位语义，本地可借鉴）。
- `DemoResetWorker`——零售演示机定时重置（tracker+resetter+
  workManager 三注入），Harmony 无对应场景，fail-closed。
- `UnresolvableWorker`——WorkManager 孤儿任务安全桩（纯 Worker
  返回常量结果），架构注记。
- `HandwritingPackDownloadWorker` 两版本均存在，非 1.4.2 新增
  （修正此前"新增"印象）。

## 验收

- Replay 5/5 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。
