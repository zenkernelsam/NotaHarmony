# ADR-0713 — 原版 1.4.2 模板同步管道维持 fail-closed

日期：2026-09-29
状态：已登记（版本差·后端边界；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-769-original-template-sync.md`
Replay：`docs/migration/replays/d02-original-template-sync.mjs`
上游：ADR-0708、Phase 764（CustomTemplatesDatabase schema）、
ADR-0711（TemplatePaperInfo.pendingSync）

## 背景

Phase 764 登记的 `CustomTemplate.uploadState/syncedName/assetId` 与
`PendingTemplateDeletion` 墓碑队列由两条 WorkManager 管道驱动：

- `CustomTemplateSyncWorker` → `s93` 编排器（双互斥 + 原子进度 +
  SYNC 域异常通道 + 分析打点），逐项经 `e93` 处理；
- `TemplatePageSyncWorker` → `bth` 页面级协调器（对应
  `TemplatePaperInfo.pendingSync` 列）；
- `kuc` 以 `DELETE ... WHERE assetId IN (...)` 批量排空墓碑。

## 决策

维持 **fail-closed**：同步对端为 GingerLabs 模板后端，无公开协议；
本地仅登记 schema 与排空语义。不实现 Worker 等价物，不伪造端点。

静态缺口登记：`s93.e()` 上传媒介与 `uploadState` 取值域在反编译
输出中不可恢复，不臆造。

## 后果

- `d02-original-template-sync.mjs` 钉住双 Worker、s93 结构特征
  与墓碑排空语句。
- T-042 输入补齐模板簇"本地 schema + 同步管道"双侧证据。
