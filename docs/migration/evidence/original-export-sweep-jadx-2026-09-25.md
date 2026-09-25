# 原版导出缓存清扫补全证据（JADX，decompiled_1.0.3）

证据日期：2026-09-25
证据来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources`
关联既有移植：`note/src/main/ets/data/NoteExportTemporaryArtifactCleanup.ets`

## 原版 `g64`（ExportFileRepository 清扫主体）

`defpackage/g64.java`：

- 常量（static 块，23-27 行）：
  - `f = ijg.r0(24, dr3.HOURS)` —— 暂存目录 **TTL 24 小时**；
  - `g = ijg.r0(15, dr3.MINUTES)` —— 周期 WorkManager 间隔
    **15 分钟**（恰为 WorkManager 最小周期间隔）。
- `a()` 清扫流程：
  1. 遍历 `c()`（`getCacheDir()/exports`）下所有目录；
  2. `d(file2)`（带 `.created` 标记的合法导出目录）且
     `now - .created.mtime >= 24h` → `tf4.u0(file2)` 递归删除；
  3. 存活目录总大小 `jE > 524288000`（**500 MB**）时，按 `.created`
     升序逐个 `tf4.u0` 直至 ≤ 500 MB —— LRU 容量上限；
  4. 第三轮按 `.created` 排序（最新在前）供查询。
- `ExportSweepWorker`（`data/library/state/`）为周期执行壳；
  `f64` 中另有 `tf4.u0(c())` 整目录清空 + `CancelWorkByName`
  （特性关闭/退役路径）。

## 原版 `gv2` 启动清扫

`d02-note-export-startup-cleanup.mjs` 既有证据已锁：
`svd.n0(name, "temp_" ... file.delete())` —— owner 启动时清
`temp_` 前缀中断缓存工件。

## Harmony 侧现状（Phase ~600s 已有移植）

- 各导出器在 `context.tempDir` 暂存、成功路径 `finally` 中
  `unlinkSync`：
  - `NoteExporter`: `export_<ts>.note`
  - `PagePdfExporter`: `note_export_<ts>.pdf`、`note_export_enc_<ts>.pdf`
  - `PageImageExporter`: `page_export_<ts>.(png|jpg)`、
    `pages_export_<ts>.zip`
- `cleanupInterruptedNoteExports(tempDir)` 于 `DatabaseManager.
  openAndMigrate` 首个 RDB open 前运行，清死进程遗留。

## 缺口

既有正则 `^export_\d+\.note$` 只覆盖 `.note` 暂存；PDF/图像/zip
五类暂存名在进程死亡路径下会滞留 `tempDir`（成功路径有 finally
unlink，但崩溃/杀进程不留 finally）。原版 `g64` 清扫语义为
「整个暂存区 + 启动期 temp_ 中断工件」，覆盖面为全量导出前缀。

## Harmony 决策

- `NOTE_EXPORT_ARTIFACT_NAME` 扩为五前缀联合正则：
  `export_\d+\.note | note_export_(enc_)?\d+\.pdf |
  pages?_export_\d+\.(png|jpe?g|zip)`。
- 不引入 24h TTL / 15min 周期 / 500MB LRU：Harmony 无持久
  provider 暂存目录（picker save 直写目标 URI），启动清扫即
  「凡遗留皆死进程工件」，TTL/周期/LRU 无对应物，按结构性差异
  登记而非移植。
- 仍保持：非递归、仅删文件、直接子路径复核、逐文件失败隔离。

## 涉及原版符号

`defpackage`: `g64` `f64` `r64` `s64` `gv2` `svd` `tf4` `zq3`
`ijg` `dr3` `dag`；`data.library.state.ExportSweepWorker`、
`data.note.assets.NoteAssetDownloadWorker`（后者为同步下载 worker，
云端资产拉取属后端边界，另册登记）。

## 未验证声明

- 500 MB LRU 与 24h TTL 的真机效果未复现（Harmony 侧无对应
  持久暂存区）。
- `.created` 标记文件的写入侧在 `f64`（导出目录创建时打点）。
