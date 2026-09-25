# Phase 735 报告：导出暂存启动清扫覆盖面补全

- 日期：2026-09-25
- 性质：实现补全（既有移植的覆盖面缺口）
- ADR：ADR-0683
- 证据：`original-export-sweep-jadx-2026-09-25.md`
- Replay：`d02-original-export-sweep.mjs` + 更新 `d02-note-export-startup-cleanup.mjs`

## 原版行为（JADX）

`g64`（ExportFileRepository）管理 `getCacheDir()/exports` 持久暂存区：

- `.created` 标记打点；**TTL 24 小时**（`ijg.r0(24, dr3.HOURS)`）；
- 存活目录总大小超 **500 MB**（524288000）时按 `.created` 升序
  LRU 删除；
- `ExportSweepWorker` 周期 **15 分钟**（WorkManager 最小间隔）；
- `f64` 另有整目录清空 + `CancelWorkByName` 退役路径；
- `gv2` 在 owner 启动时清 `temp_` 中断缓存工件。

## 缺口与修复

Harmony 早期已把「启动期清扫中断导出工件」移植为
`cleanupInterruptedNoteExports`（在首个 RDB open 前运行于
`context.tempDir`），但正则只收 `export_\d+\.note` ——
`note_export_*.pdf`、`note_export_enc_*.pdf`、`page_export_*.(png|jpg)`、
`pages_export_*.zip` 四类暂存名在进程死亡路径下滞留 tempDir。

本阶段将 `NOTE_EXPORT_ARTIFACT_NAME` 扩为五前缀联合正则，与
三个 exporter 的实际暂存命名逐一对齐；注释同步更正覆盖面。

## 刻意不移植

- **24h TTL / 15min 周期 / 500MB LRU**：管理的是原版持久
  share-provider 暂存区。Harmony 无对应持久目录（picker save
  直写目标 URI、成功路径 finally unlink）；启动清扫视野内的匹配
  文件恒为死进程遗留，TTL/LRU 无对象，按结构性差异登记。

## 安全不变量（保持不变）

- 非递归（`recursion: false`）、仅删普通文件；
- `directChildPath` 直接子路径复核后才 unlink；
- 逐文件失败隔离，计入 report；
- 仍在首个 RDB open 前运行（无并发导出竞争窗口）。

## 验证

- 专项 Replay：40 项断言（含正则正/负样本模型）。
- 更新 `d02-note-export-startup-cleanup.mjs`：正则钉演进 +
  运行时模型扩至六种暂存名（15/15 绿）。
- 全量 Desktop Replay + 双 HAP 按协议复验。
