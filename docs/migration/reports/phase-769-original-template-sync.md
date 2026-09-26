# Phase 769 — 原版 1.4.2 模板同步管道登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-769-original-template-sync.md`
ADR：`ADR-0713-original-template-sync.md`
Replay：`d02-original-template-sync.mjs`（6/6）

## 本阶段做了什么

补全 Phase 764 schema 的同步侧：追踪
`CustomTemplateSyncWorker`/`TemplatePageSyncWorker` 两条
WorkManager 管道的内部结构。

## 发现

- `s93` 编排器：11 协作者注入 + 双 `oha` 互斥（入队/出队串行化）
  + `AtomicInteger` 进度 + `zg9.SYNC` 域未捕获异常通道 +
  `CustomTemplateSync` 分析打点；`b()` 为 mutex 排空循环，
  逐项 `e93.a()` 处理。
- `kuc`：`DELETE FROM PendingTemplateDeletion WHERE assetId IN (...)`
  为墓碑批量排空——上传确认后出队。
- `bth`：页面级同步协调器（四个 suspend 操作），对应
  `TemplatePaperInfo.pendingSync` 列——纸张页信息走独立同步线。
- uploadState/syncedName/assetId 三列与该管道闭环：
  本地行 ↔ 远端资产映射。

## 分类与缺口

- 维持 fail-closed（模板云后端）；`s93.e()` 上传媒介与
  uploadState 取值域不可恢复，已登记不臆造。

## 验收

- Replay 6/6 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。
