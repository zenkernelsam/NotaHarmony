# ADR-0767 — WorkManager 后台任务面闭合

## 状态

已接受（全部登记 fail-closed 或平台等价）。

## 背景

原版后台任务面由 WorkManager/CoroutineWorker 承载：1.0.1/1.0.3 为 7 个
同步与资源型 worker，1.4.2 增至 15 个（新增维护/模板同步×2/画廊上传/
贴纸预取×2/零售演示重置/容错终结各一）。全部经 WorkerFactory 映射与
唯一工作名调度。

Harmony 无 WorkManager 对应物；`ets/` 全量扫描确认除录音
AUDIO_RECORDING 连续任务外，无 workScheduler/reminderAgent 注册。

## 决定

1. **同步型 worker 族 fail-closed**：LibraryStateUploader/NoteOpsUpdater/
   NoteAsset 三件套/GalleryMutationUploader/模板同步×2 均为云同步
   outbox 驱动——Harmony 本地优先架构不承载（与同步层 fail-closed
   一致）。
2. **资源下载器 fail-closed**：HandwritingPackDownloadWorker（MyScript
   包 CDN）、StickerPack 下载/预取——Harmony 侧识别/贴纸资源由打包
   或已登记 fail-closed 集群承担。
3. **平台机制不复制**：UnresolvableWorker（WorkManager 容错壳）、
   DemoResetWorker（零售演示重置）无 Harmony 场景。
4. **ExportSweepWorker 语义吸收**：导出残留清扫由 Harmony 侧临时
   文件生命周期管理等价承担，不设常驻 worker。

## 后果

- 后台任务面闭合：15 个原版 worker 全部归类。
- 新增 `d02-worker-inventory.mjs` 回归：版本差、集群归因、
  Harmony 无调度器核验。

## 已验证

- `d02-worker-inventory.mjs`：9/9。
- 全量 Desktop Replay + clean/default、`note@ohosTest` HAP 构建（随 Phase 823 提交）。
