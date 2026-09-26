# ADR-0789 — Worker 与 Initializer 清单归档

- 状态：已接受
- 证据：`docs/migration/evidence/phase-845-worker-initializer.md`
- 回放：`docs/migration/replays/d02-worker-initializer.mjs`（13/13）

## 决定

1. WorkManager 面归档：15 Worker 类（12 直系 CoroutineWorker、
   `NoteAssetDownload/Upload` 继承 `NoteAssetTransferWorker` 基类、
   `UnresolvableWorker` 占位桩）；除 `ExportSweepWorker`（本地
   清杂、低价值、登记未实现）外全部 sync/后端/Play
   AssetDelivery 依赖 → fail-closed。
2. Initializer 面归档：4 DataStore 域（user/theme/editor-settings/
   haptic）+ 2 androidx.startup（836 已记）；Harmony 对应为
   `ThemeStore.init()` + DataStore-preferences 惰性装载，
   初始化时机差异文档化。
3. Harmony 无 `workScheduler`/`transientTask` 使用——后台
   执行仅保留 834 的连续任务映射，其余不复刻。

## 后果

`com.gingerlabs.notability` 非混淆类的调度/初始化面完整
闭合；Worker 基础设施差异经平台映射登记。
