# 原版 1.4.2 后台 Worker 清单登记（Phase 775 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 证据源：两版本 `com/gingerlabs` 全量 `*Worker.java` 文件名 diff +
>   `domain/maintenance/`、`app/demo/`、`core/workmanager/` 包
> 性质：1.4.2 版本差证据登记；无 Harmony 代码变更。

## 一、Worker 级 diff（1.0.3 → 1.4.2）

新增 8 个、删除 0 个：

| Worker | 归属 | 登记 |
|---|---|---|
| `GalleryMutationUploaderWorker` | gallery/outbox | Phase 766 |
| `CustomTemplateSyncWorker` | templates/sync | Phase 769 |
| `TemplatePageSyncWorker` | settings/sync | Phase 769 |
| `StickerPackDownloadWorker` / `StickerPackPrefetchWorker` | feature/note/stickers/packs | Phase 770 |
| `BackgroundMaintenanceWorker` | domain/maintenance | 本阶段 |
| `DemoResetWorker` | app/demo | 本阶段 |
| `UnresolvableWorker` | core/workmanager | 本阶段 |

（`HandwritingPackDownloadWorker` 1.0.3 已存在，非新增。）

## 二、新 Worker 语义

### `BackgroundMaintenanceWorker`（domain/maintenance）

- CoroutineWorker，注入 `cs0`（维护 pass 编排）。
- 配套 `ForegroundReturned extends CancellationException`
  （"App returned to the foreground"）——**前台回归即中止维护**：
  后台清扫主动让位于用户操作，本地语义值得借鉴。
- 同包 `a`/`b`（内部类）——具体清扫项未完全反编译。

### `DemoResetWorker`（app/demo）

- CoroutineWorker，注入 `mw3`（demo 状态追踪）+ `sw3`（重置器）
  + `l6k`（WorkManager）——零售演示机定时重置数据。
- `sw3`/`mw3` 为薄封装（Context + tracker），重置内部未完全解出。

### `UnresolvableWorker`（core/workmanager）

- 普通 `Worker`，返回 `xb9`（success/failure 常量）——**孤儿任务
  安全桩**：WorkManager 重启后无法重建依赖的遗留工作请求统一走
  此桩快速终结，避免挂起。属健壮性脚手架，本地语义。

## 三、分类

| Worker | 分类 |
|---|---|
| BackgroundMaintenanceWorker | 本地语义（后台清扫 + 前台让位）——可借鉴，待审 |
| DemoResetWorker | 零售演示模式——版本差，Harmony 无零售演示需求登记 fail-closed |
| UnresolvableWorker | WorkManager 专署脚手架——Harmony WorkScheduler 无同构孤儿任务问题，登记为架构注记 |
