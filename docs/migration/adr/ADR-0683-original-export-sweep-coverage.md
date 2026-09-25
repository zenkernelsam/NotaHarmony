# ADR-0683: 导出暂存启动清扫覆盖面补全（g64/ExportSweepWorker 对齐）

- 状态：已接受（实现补全）
- 日期：2026-09-25
- 阶段：Phase 735
- 证据：`docs/migration/evidence/original-export-sweep-jadx-2026-09-25.md`
- Replay：`d02-original-export-sweep.mjs` + 更新 `d02-note-export-startup-cleanup.mjs`

## 背景

原版 `g64`（ExportFileRepository）对 `getCacheDir()/exports` 持久
暂存区做 24h TTL + 500MB LRU + 15min 周期清扫，`gv2` 另在 owner
启动时清 `temp_` 中断工件。Harmony 早期已将「启动期清扫中断
导出工件」移植为 `cleanupInterruptedNoteExports`，但正则仅覆盖
`export_*.note` —— PDF/图像导出器（`note_export_*`、`page_export_*`、
`pages_export_*.zip`）的暂存名在进程死亡路径下会滞留 `tempDir`。

## 决策

1. **覆盖面补齐（直接移植意图）**：`NOTE_EXPORT_ARTIFACT_NAME`
   扩为五前缀联合正则，与三处 producer 的命名逐一对齐：
   `export_<ts>.note`、`note_export_<ts>.pdf`、
   `note_export_enc_<ts>.pdf`、`page_export_<ts>.(png|jpg)`、
   `pages_export_<ts>.zip`。
2. **不移植 24h TTL / 15min 周期 / 500MB LRU**：这些是原版
   **持久 share-provider 暂存区**（ExportFileProvider 供外部
   读取的目录，文件要活到分享完成）的管理策略。Harmony 导出
   直接 `tempDir`→`DocumentViewPicker.save`→目标 URI→finally
   unlink，无持久暂存区；启动清扫看到的任何匹配文件必然来自
   死进程（新进程尚未产生导出），故恒为过期——TTL/周期/LRU
   属于无对应物的结构性差异，登记不移植。
3. **保持既有安全不变量**：非递归、仅删普通文件、直接子路径
   复核（`directChildPath`）、逐文件失败隔离、清理在首个 RDB
   open 前运行。

## Harmony 实现

- `NoteExportTemporaryArtifactCleanup.ets`：
  `NOTE_EXPORT_ARTIFACT_NAME` 扩为
  `/^(?:export_\d+\.note|note_export_(?:enc_)?\d+\.pdf|pages?_export_\d+\.(?:png|jpe?g|zip))$/`，
  注释更新为覆盖全量 exporter 前缀。
- 调用点不变（`DatabaseManager.openAndMigrate` → RDB open 前）。

## 边界与限制

- 匹配仍要求**形如 `<prefix>_<数字>.<已知扩展>`**：非数字时间戳、
  未知扩展、用户自建文件不受影响（d02 fixture 负样本锁定）。
- `note_export_enc_` 与 `note_export_` 共用前缀，正则用
  `(enc_)?` 一并覆盖。
- 未做模拟器/真机/Hypium 验证。
